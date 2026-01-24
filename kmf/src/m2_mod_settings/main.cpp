#include <cstring>
#define wxNO_HTML_LIB
#define wxNO_QA_LIB
#define wxNO_XRC_LIB
#define wxNO_AUI_LIB
#define wxNO_PROPGRID_LIB
#define wxNO_RIBBON_LIB
#define wxNO_RICHTEXT_LIB
#define wxNO_MEDIA_LIB
#define wxNO_STC_LIB
#define wxNO_WEBVIEW_LIB
#define wxNO_GL_LIB
#define wxNO_XML_LIB
#define wxNO_EXPAT_LIB
#define wxNO_NET_LIB
#define wxHAS_DPI_INDEPENDENT_PIXELS
#define wxHAVE_DPI_INDEPENDENT_PIXELS

#include "gui.hpp"

#include <algorithm>
#include <fstream>
#include <string>
#include <map>
#include <chrono>
#include <mutex>

#include <stdio.h>
#include <math.h>

#include <windows.h>
#include <tlhelp32.h>
#include <shellapi.h>
#include <math.h>

#include "resource.h"

#define WTEXT2(x) L ## x
#define WTEXT(x) WTEXT2(x)

HWND m2_hwnd = NULL;
RECT wnd_rect = {20, 20, 405, 720};
HFONT hFont = NULL;
ModSettingsFrame *main_window = NULL;
wxFont font_big, font_text, font_mid, font_btn, font_small;
std::vector<ModDataEntry> *mods_data;
std::vector<std::pair<int, int>> outline_offests = {
    { 1,  0},
    { 0,  1},
    {-1,  0},
    { 0, -1},
    
    { 1,  1},
    {-1, -1},
    {-1,  1},
    { 1, -1},
    
    { 2,  0},
    { 2, -1},
    { 2,  1},
    
    {-2,  0},
    {-2, -1},
    {-2,  1},
    
    { 0,  2},
    {-1,  2},
    { 1,  2},
    
    { 0, -2},
    {-1, -2},
    { 1, -2}
};
wxCursor cursor_blank;
HHOOK mouse_hook;
volatile bool program_closing = false;
std::chrono::high_resolution_clock::time_point frame_timer;
HWND tmp_hwnd;
std::mutex find_hwnd_mutex;

typedef struct {
    const char *bytes;
    size_t size;
} data_file_t;
char* data = NULL;
std::map<std::string, data_file_t> graphic_map;

inline void debug_print(const char * str) {
#if defined(DEBUG) || defined(_DEBUG)
    printf("%s", str);
#endif // DEBUG
}

static void parse_indexed_file_amalgamation(std::filesystem::path *data_path) {
    std::ifstream data_file(*data_path, std::ios::binary);
    std::streampos data_size = 0;
    std::vector<const char *> files;

    data_size = data_file.tellg();
    data_file.seekg(0, std::ios::end);
    data_size = data_file.tellg() - data_size;
    data_file.seekg(0);

    data = (char *)malloc((uint64_t)data_size * sizeof(char));
    data_file.read(data, data_size);

    const uint32_t *amalgamation_size;
    const char *file_name;
    const uint32_t *file_size;
    const char* ptr;

    amalgamation_size = (uint32_t *)data;
    for (const char *ptr = data + 4; ptr - data < *amalgamation_size;) {
        data_file_t file_info = {NULL , 0};
        size_t name_size = 0;

        file_name = ptr;
        name_size = strlen(file_name);
        file_size = (uint32_t *)(ptr + name_size + 1);
        file_info.size = *file_size;
        files.push_back(file_name);
        graphic_map.emplace(file_name, file_info);

        ptr += name_size + 5;
    }

    ptr = data + *amalgamation_size;
    for (size_t i = 0; i < files.size(); i++) {
        size_t file_size;

        file_size = graphic_map[files[i]].size;
        graphic_map[files[i]].bytes = ptr;
        ptr += file_size;
        {
            uint32_t start, end;
            start = *((uint32_t*)(graphic_map[files[i]].bytes));
            end = *((uint32_t *)(graphic_map[files[i]].bytes + file_size - 4));
        }
    }
}

wxMemoryInputStream getDataStream(data_file_t &file_data) {
    return wxMemoryInputStream(file_data.bytes, file_data.size);
}

static void load_font() {
    DWORD added;
    AddFontMemResourceEx((void *)graphic_map["resources_font_otf"].bytes, graphic_map["resources_font_otf"].size, 0, &added);
}

static void setDoubleBuffered(wxWindow *wnd) {
#ifdef __WXMSW__
    HWND hwnd = (HWND)wnd->GetHandle();
    long oldstyle = ::GetWindowLong(hwnd, GWL_EXSTYLE);
    SetWindowLong(hwnd, GWL_EXSTYLE, oldstyle | WS_EX_COMPOSITED);
#endif
}

static DWORD find_pid(const std::wstring& processName)
{
    DWORD curPid = GetCurrentProcessId();

    PROCESSENTRY32 processInfo;
    processInfo.dwSize = sizeof(processInfo);

    HANDLE processesSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
    if (processesSnapshot == INVALID_HANDLE_VALUE) {
        return 0;
    }

    Process32First(processesSnapshot, &processInfo);
    if (!processName.compare(processInfo.szExeFile) && curPid != processInfo.th32ProcessID)
    {
        CloseHandle(processesSnapshot);
        return processInfo.th32ProcessID;
    }

    while (Process32Next(processesSnapshot, &processInfo))
    {
        if (!processName.compare(processInfo.szExeFile) && curPid != processInfo.th32ProcessID)
        {
            CloseHandle(processesSnapshot);
            return processInfo.th32ProcessID;
        }
    }

    CloseHandle(processesSnapshot);
    return 0;
}

static BOOL CALLBACK filter_hwnd_by_pid(HWND hwnd, LPARAM lParam) {
    DWORD lpdwProcessId;
    GetWindowThreadProcessId(hwnd, &lpdwProcessId);
    if (lpdwProcessId == lParam)
    {
        tmp_hwnd = hwnd;
        return FALSE;
    }

    return TRUE;
}

static HWND find_hwnd_by_pid(DWORD pid) {
    std::unique_lock<std::mutex> lock(find_hwnd_mutex);

    tmp_hwnd = NULL;
    EnumWindows(filter_hwnd_by_pid, pid);

    return tmp_hwnd;
}

static void erase_bg_handler(wxEraseEvent& event) {}

static void constraint_image(wxImage* img, const wxSize* size) {
    int new_width, new_height;
    double ratio_img, ration_sz;

    new_width = img->GetWidth();
    new_height = img->GetHeight();
    ratio_img = new_width / (double)new_height;
    ration_sz = size->x / (double)(size->y);

    if (ratio_img > ration_sz) {
        new_width = size->x;
        new_height = new_width / ratio_img;
    }
    else {
        new_height = size->y;
        new_width = new_height * ratio_img;
    }

    img->Rescale(new_width, new_height, wxIMAGE_QUALITY_BICUBIC);
}

static void close_program() {
    program_closing = true;
    UnhookWindowsHookEx(mouse_hook);

    if (main_window != NULL)
        main_window->Close();
}

static void save_mod_settings_wrapper() {
    save_mod_settings();
    close_program();
}

static void open_sponsor_link() {
#define SPONSOR_LINK "https://pepega.online"

    if ((int)ShellExecuteW(0, 0, WTEXT(SPONSOR_LINK), 0, 0, SW_SHOW) > 32)
        return;
    
    if ((int)ShellExecuteA(0, "open", SPONSOR_LINK, 0, 0, SW_SHOWNORMAL) > 32)
        return;

    SHELLEXECUTEINFOW sei = { sizeof(sei) };
    sei.lpVerb = L"open";
    sei.lpFile = WTEXT(SPONSOR_LINK);
    sei.hwnd = NULL;
    sei.nShow = SW_NORMAL;

    if (!ShellExecuteExW(&sei)) {
        system("start " SPONSOR_LINK);
    }

#undef SPONSOR_LINK 
}

static void display_setting_help(MagicModSettingLabel *label, const std::string *setting) {
    const SettingPossibleValues &possible_values = *get_setting_possible_values(setting);
    std::string msg = "";

    switch (possible_values.type) {
        case SettingType::player_target:
            msg += "Target player settings must be in format:\n"
                "    <target>\n\n"
                "Possible target values are:\n";
            break;
        case SettingType::keyboard_hotkey:
            msg += "Keyboard hotkey settings must be in format:\n"
                "    <button> [ + <button> [ + <button> [ ... ] ] ]\n\n"
                "Possible keys available for binding are:\n";
            break;
        case SettingType::gamepad_hotkey:
            msg += "Gamepad hotkey settings must be in format (you can mix button types):\n"
                "    <button> [ + <button> [ + <button> [ ... ] ] ]\n\n"
                "Possible keys available for binding on XBOX controller are:\n";
            break;
        case SettingType::wizard_name:
        case SettingType::profile_name:
            msg += "This must be a utf8 string.\n\n"
                "Probably it is best to use ASCII characters and avoid using any special characters.";
            break;
        default:
            return;
    }

    if (possible_values.values) {
        for (const char *value : *possible_values.values) {
            if (value != NULL) {
                msg += "    ";
                msg += value;
                msg += "\n";
            }
            else {
                if (possible_values.type == SettingType::gamepad_hotkey)
                    msg += "\nPossible keys available for binding on Playstation controller are:\n";
            }
        }
    }

    MessageBoxA(NULL, msg.c_str(), "Format for this setting", MB_ICONINFORMATION);
}

static wxImage image_from_resource(const char *resource) {
    wxMemoryInputStream stream = getDataStream(graphic_map[resource]);

    return wxImage(stream, wxBITMAP_TYPE_PNG);
}

static void resize_image(wxImage *image, wxSize size) {
    image->Rescale(size.x, size.y, wxIMAGE_QUALITY_BICUBIC);
}

static LRESULT CALLBACK MouseHookEvent(int nCode, WPARAM wParam, LPARAM lParam) {
    if (!program_closing) {
        std::chrono::high_resolution_clock::time_point cur_time = std::chrono::high_resolution_clock::now();
        auto time_left = std::chrono::duration_cast<std::chrono::milliseconds>(cur_time - frame_timer);

        if (time_left.count() > 0) {
            main_window->UpdateCustomCursorPos();
            frame_timer = std::chrono::high_resolution_clock::now() + std::chrono::milliseconds(10);
        }
    }

    return CallNextHookEx(mouse_hook, nCode, wParam, lParam);
}

// class ModSettings

bool ModSettings::OnInit()
{
    ModSettingsFrame* frame = new ModSettingsFrame();
    frame->Show(true);
    return true;
}

wxIMPLEMENT_APP_NO_MAIN(ModSettings);

// class ImgPanel

ImgPanel::ImgPanel(wxWindow* parent, const char* file_name, const wxPoint& pos, const wxSize& size, const bool constraint, long style)
    : wxPanel(parent, wxID_ANY, pos, size, style)
{

    this->constraint = constraint;
    img = image_from_resource(file_name);

    Setup();
}

ImgPanel::ImgPanel(wxWindow* parent, wxInputStream *stream, const wxPoint& pos, const wxSize& size, const bool constraint, long style)
    : wxPanel(parent, wxID_ANY, pos, size, style)
{
    this->constraint = constraint;
    img = wxImage(*stream, wxBITMAP_TYPE_PNG);

    Setup();
}

ImgPanel::ImgPanel(wxWindow* parent, wxImage *img, const wxPoint& pos, const wxSize& size, const bool constraint, long style)
    : wxPanel(parent, wxID_ANY, pos, size, style)
{
    this->constraint = constraint;
    this->img = *img;

    Setup();
}

void ImgPanel::Setup() {
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);

    Bind(wxEVT_PAINT, &ImgPanel::OnPaint, this);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    const wxSize size = GetSize();

    if (!constraint)
        resize_image(&img, size);
    else
        constraint_image(&img, &size);
}

void ImgPanel::OnPaint(wxPaintEvent& event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);

    dc.DrawBitmap(img, 0, 0);
}

// class DoubleBufferedTextCtrl

DoubleBufferedTextCtrl::DoubleBufferedTextCtrl(wxWindow *parent, const wxPoint &pos, const wxSize &size, wxFont *font, wxColour *colour, std::function<void(const char *)> callback)
    : wxTextCtrl(parent, wxID_ANY, wxEmptyString, pos, size, wxNO_BORDER | wxTE_CENTER)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);

    this->font = font;
    this->colour = colour;
    this->callback = callback;

    SetFont(*font);

    Bind(wxEVT_PAINT, &DoubleBufferedTextCtrl::OnPaint, this);
    Bind(wxEVT_TEXT, &DoubleBufferedTextCtrl::OnTextChanged, this);
    Bind(wxEVT_KILL_FOCUS, &DoubleBufferedTextCtrl::OnKillFocus, this);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);
}

void DoubleBufferedTextCtrl::OnKillFocus(wxFocusEvent &event) {
    SetSelection(0, 0);
    main_window->Redraw(GetParent());
    event.Skip();
}

void DoubleBufferedTextCtrl::OnPaint(wxPaintEvent& event) {
    // i know it is inefficient, there is some weird bug with transparency
    this->selection_image = image_from_resource("resources_selection_png");

    setDoubleBuffered(this);
    wxPaintDC dc(this);

    long from = 0, to = 0;
    const wxString &wx_text = GetLineText(0);
    wxString wx_before, wx_selected = "", wx_after = "";

    GetSelection(&from, &to);

    if ((prev_from != from) || (prev_to != to)) {
        prev_from = from;
        prev_to = to;

        main_window->Redraw(GetParent());
    }
    
    if (from != 0 || to != 0) {
        wx_before = wxString(wx_text.c_str(), from);
        wx_selected = wxString(wx_text.c_str() + from, to - from);
        wx_after = wxString(wx_text.c_str() + to);
    }
    else {
        wx_before = wx_text;
    }

    dc.SetFont(*font);

    const int from_x_pos = PositionToCoords(from).x;
    const int to_x_pos = PositionToCoords(to).x;
    const wxSize size = GetSize();
    const wxSize size_text = dc.GetTextExtent(wx_text);
    const wxSize size_before = dc.GetTextExtent(wx_before);
    const wxSize size_selected = dc.GetTextExtent(wx_selected);
    const wxSize size_after = dc.GetTextExtent(wx_after);
    int sel_size = to_x_pos - from_x_pos;

    int sel_start = from_x_pos + round(sel_size / 2.0) - round(size_selected.x / 2.0);
    int sel_end = sel_start + size_selected.x;

    printf("    sel_start :: %d\n    sel_end :: %d\n    diff :: %d\n\n", sel_start, sel_end, size_selected.x - sel_size);

    int spacing = (size_text.x - (size_before.x + size_selected.x + size_after.x));
    if (size_selected.x > 0 && size_after.x > 0)
        spacing = round(spacing / 2.0);


    dc.SetTextForeground(*colour);
    if (size_selected.x > 0) {
        resize_image(&selection_image, { size_selected.x, size.y });
        dc.DrawBitmap(selection_image, sel_start, 0);
        dc.DrawLabel(wx_selected, { sel_start, 0, size_selected.x, size.y }, wxALIGN_CENTER);
    }

    sel_start -= spacing;
    sel_end += spacing;

    if (size_after.x > 0) {
        dc.DrawLabel(wx_after, { sel_end, 0, size_after.x, size.y }, wxALIGN_CENTER);
    }

    if (size_selected.x == 0 && size_after.x == 0)
        sel_start = round(size.x / 2.0) + round(size_before.x / 2.0);

    if (size_before.x > 0) {
        dc.DrawLabel(wx_before, { sel_start - size_before.x, 0, size_before.x, size.y }, wxALIGN_CENTER);
    }
}

void DoubleBufferedTextCtrl::OnTextChanged(wxCommandEvent &event) {
    callback(GetLineText(0).mb_str(wxConvUTF8));
    main_window->Redraw(GetParent());
}

// class DoubleBufferedText

DoubleBufferedText::DoubleBufferedText(wxWindow* parent, const char* label, bool free_label, const wxPoint& pos, const wxSize& size)
    : wxPanel(parent, wxID_ANY, pos, size, 0)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    Bind(wxEVT_PAINT, &DoubleBufferedText::OnPaint, this);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    this->label = label;
    this->free_label = free_label;
    font = &font_text;
    drop_shadow = false;
    color = &color_text;
    align = wxALIGN_CENTER;

    int w, h;
    w = size.x;
    h = size.y;

    for (auto offset : outline_offests)
        outline_positions.push_back(wxRect(
            offset.first,
            offset.second,
            w + offset.first,
            h + offset.second));
}

DoubleBufferedText::~DoubleBufferedText() {
    if (free_label)
        delete label;
}

void DoubleBufferedText::OnPaint(wxPaintEvent& event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);

    dc.SetFont(*font);

    if (drop_shadow) {
        dc.SetTextForeground(color_shadow);
        for (auto rect : outline_positions)
            dc.DrawLabel(label, rect, align);
    }

    dc.SetTextForeground(*color);
    dc.DrawLabel(label, { 0, 0, GetSize().x, GetSize().y }, align);
}

// class MagicTextFilterCtrl

MagicTextFilterCtrl::MagicTextFilterCtrl(wxWindow* parent, const char* label, const wxPoint& pos, const wxSize& size)
    : ImgPanel(parent, "resources_elem_text_ovr_png", pos, size)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    bounding_box = new wxPanel(
        this,
        wxID_ANY,
        {10, (size.y - font_text.GetPixelSize().y) / 2},
        {size.x - 20, font_text.GetPixelSize().y },
        0);
    bounding_box->SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    bounding_box->Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    std::function<void(const char *)> functor = [this](const char *filter) { this->SetFilter(filter); };
    textCtrl = new DoubleBufferedTextCtrl(bounding_box, { 0, 0 }, bounding_box->GetSize(), &font_text, &color_text, functor);
    filter_elem = NULL;
}

void MagicTextFilterCtrl::Subscribe(Filterable *filterable) {
    filter_elem = filterable;
}

void MagicTextFilterCtrl::SetFilter(const char *filter) {
    if (filter_elem != NULL)
        filter_elem->SetFilter(filter);
}

// class MagicTextFilterCtrl

MagicTextSettingCtrl::MagicTextSettingCtrl(wxWindow* parent, const wxPoint& pos, const wxSize& size, const char *cur_value, std::function<bool(const char *)> callback)
    : ImgPanel(parent, "resources_elem_text_ovr_png", pos, size)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);
    this->callback = callback;

    bounding_box = new wxPanel(
        this,
        wxID_ANY,
        {10, (size.y - font_small.GetPixelSize().y) / 2},
        {size.x - 20, font_small.GetPixelSize().y },
        0);
    bounding_box->SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    bounding_box->Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    std::function<void(const char *)> functor = [this](const char *value) { this->SetValue(value); };
    textCtrl = new DoubleBufferedTextCtrl(bounding_box, { 0, 0 }, bounding_box->GetSize(), &font_small, &color_text, functor);
    printf("cur value :: [%s]\n", cur_value);
    textCtrl->SetLabelText(wxString::FromUTF8(cur_value));
}

void MagicTextSettingCtrl::SetValue(const char *value) {
    printf("set value :: [%s]\n", value);
    if (callback(value))
        textCtrl->colour = &color_text;
    else
        textCtrl->colour = &color_error;
}

// class MagicButton

MagicButton *MagicButton::CreateMagicButton(wxWindow* parent, const char* label, void (*callback)(void), const wxPoint& pos, const wxSize& size) {
    MagicButton *obj = new MagicButton(parent, pos, size);
    obj->InitImages(size);
    obj->drawGUI = true;

    obj->label = label;
    obj->callback = callback;

    obj->Bind(wxEVT_PAINT, &MagicButton::OnPaint, obj);
    obj->Bind(wxEVT_BUTTON, &MagicButton::OnClick, obj);
    obj->font = obj->font_normal = &font_btn;
    obj->font_highlight = &font_big;

    return obj;
}

void MagicButton::SetColors(wxColour *normal, wxColour *highlight) {
    normal_color = normal;
    highlight_color = highlight;
    color = normal_color;
}

MagicButton::MagicButton(wxWindow *parent, const wxPoint& pos, const wxSize& size)
    : wxWindow(parent, wxID_ANY, pos, size, 0)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    Bind(wxEVT_ENTER_WINDOW, &MagicButton::OnMouseEnter, this);
    Bind(wxEVT_LEAVE_WINDOW, &MagicButton::OnMouseLeave, this);
    Bind(wxEVT_LEFT_DOWN, &MagicButton::OnMouseDown, this);
    Bind(wxEVT_LEFT_UP, &MagicButton::OnMouseUp, this);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    int w, h;
    w = size.x;
    h = size.y;

    for (auto offset : outline_offests)
        outline_positions.push_back(wxRect(
            offset.first,
            offset.second,
            w + offset.first,
            h + offset.second));

    normal_color = &color_text;
    highlight_color = &color_highlight;
    color = normal_color;
    font = NULL;
    click_registered = can_click = false;

    //this->SetCursor(stock_pointer_cursor);
}

void MagicButton::InitImages(const wxSize& size) {
    wxMemoryInputStream btn_part_l_png_stream = getDataStream(graphic_map["resources_btn_part_l_png"]);
    img_l = wxImage(btn_part_l_png_stream, wxBITMAP_TYPE_PNG);
    constraint_image(&img_l, &size);

    wxMemoryInputStream btn_part_r_png_stream = getDataStream(graphic_map["resources_btn_part_r_png"]);
    img_r = wxImage(btn_part_r_png_stream, wxBITMAP_TYPE_PNG);
    constraint_image(&img_r, &size);

    wxMemoryInputStream elem_bg_r_png_stream = getDataStream(graphic_map["resources_elem_bg_btn_png"]);
    img_bg = wxImage(elem_bg_r_png_stream, wxBITMAP_TYPE_PNG);
    img_bg.Rescale(size.x, size.y, wxIMAGE_QUALITY_BICUBIC);
}

void MagicButton::OnPaint(wxPaintEvent& event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);

    SetFont(*font);

    if (drawGUI) {
        dc.DrawBitmap(img_bg, 0, 0);
        dc.DrawBitmap(img_l, 0, 0);
        dc.DrawBitmap(img_r, img_bg.GetWidth() - img_r.GetWidth(), 0);
    }

    dc.SetFont(*font);

    if (drop_shadow) {
        dc.SetTextForeground(color_shadow);
        for (auto rect : outline_positions)
            dc.DrawLabel(label, rect, wxALIGN_CENTER);
    }

    dc.SetTextForeground(*color);
    dc.DrawLabel(label, {0, 0, GetSize().x, GetSize().y}, wxALIGN_CENTER);
}

void MagicButton::OnMouseEnter(wxEvent& event) {
    color = highlight_color;
    font = font_highlight;
    main_window->Redraw(this);
    can_click = true;
    click_registered = false;
}

void MagicButton::OnMouseLeave(wxEvent& event) {
    color = normal_color;
    font = font_normal;
    main_window->Redraw(this);
    click_registered = can_click = false;
}

void MagicButton::OnMouseDown(wxEvent &event) {
    click_registered = true;
}

void MagicButton::OnMouseUp(wxEvent &event) {
    if (can_click && click_registered)
        this->OnClick(event);
}

void MagicButton::OnClick(wxEvent& event) {
    if (callback != NULL)
        callback();
}

// class ScrollElement

ScrollElement::ScrollElement(wxWindow* parent, const wxPoint& pos, const wxSize& size)
    : wxPanel(parent, wxID_ANY, pos, size, 0)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);

    Bind(wxEVT_PAINT, &ScrollElement::OnPaint, this);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    wxMemoryInputStream scrollbar_top_png_stream = getDataStream(graphic_map["resources_scrollbar_top_png"]);
    img_top = wxImage(scrollbar_top_png_stream, wxBITMAP_TYPE_PNG);
    constraint_image(&img_top, &size);
    wxMemoryInputStream scrollbar_bottom_png_stream = getDataStream(graphic_map["resources_scrollbar_bottom_png"]);
    img_bottom = wxImage(scrollbar_bottom_png_stream, wxBITMAP_TYPE_PNG);
    constraint_image(&img_bottom, &size);

    scrl_height = 0;
    scrl_pos = 0;
}

void ScrollElement::OnPaint(wxPaintEvent& event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);
    int top_h = img_top.GetHeight();
    int bottom_h = img_bottom.GetHeight();
    int height = (scrl_height * GetSize().y);

    height -= top_h + bottom_h;

    if (height < 0)
        height = 0;

    int next_y_pos = scrl_pos * (GetSize().y - height - top_h - bottom_h);

    dc.DrawBitmap(img_top, 0, next_y_pos);
    next_y_pos += top_h;

    dc.SetPen(color_scroll);
    dc.SetBrush(color_scroll);
    dc.DrawRectangle({0, next_y_pos, GetSize().x, height});
    next_y_pos += height;

    dc.DrawBitmap(img_bottom, 0, next_y_pos);
}

void ScrollElement::SetHeight(double height) {
    if (height < 0)
        height = 0;
    if (height > 1)
        height = 1;

    scrl_height = height;
}

void ScrollElement::SetPos(double position) {
    if (position < 0)
        position = 0;
    if (position > 1)
        position = 1;

    scrl_pos = position;
}

double ScrollElement::GetHeight() {
    return scrl_height;
}

double ScrollElement::GetPos() {
    return scrl_pos;
}

// class ScrollInteract

ScrollInteract::ScrollInteract(wxWindow* parent, wxImage* img, const wxPoint& pos, const wxSize& size)
    : ImgPanel(parent, img, pos, size, false, 0)
{
    Bind(wxEVT_LEFT_UP, &ScrollInteract::OnLeftUp, this);
    Bind(wxEVT_MOTION, &ScrollInteract::OnMouseMove, this);
    Bind(wxEVT_LEFT_DOWN, &ScrollInteract::OnLeftDown, this);
    Bind(wxEVT_LEAVE_WINDOW, &ScrollInteract::OnMouseLeave, this);
    Bind(wxEVT_MOUSEWHEEL, &ScrollInteract::OnMouseWheel, this);

    pressed = false;
    scroll_element = NULL;
}

void ScrollInteract::ScrollToPos(int y) {
    double percent = 0;
    if (y > higher) {
        percent = 1.0;
    }
    else if (y > lower) {
        y = y - lower;
        percent = y / (double)(higher - lower);
    }

    SetSrollPos(percent);
}

void ScrollInteract::SetSrollPos(double pos) {
    if (pos > 1.0)
        pos = 1.0;
    if (pos < 0.0)
        pos = 0.0;

    scroll_element->SetPos(pos);
    ((MagicScrollbar *)GetParent())->ReportScrollPos(pos);

    main_window->Redraw(GetParent());
}

void ScrollInteract::OnLeftUp(wxMouseEvent& event) {
    if (scroll_element) {
        pressed = false;
        ScrollToPos(event.GetY());
    }
}

void ScrollInteract::OnMouseMove(wxMouseEvent& event) {
    if (pressed) {
        if (scroll_element) {
            ScrollToPos(event.GetY());
        }
    }
}

void ScrollInteract::OnMouseLeave(wxEvent& event) {
    pressed = false;
}

void ScrollInteract::OnLeftDown(wxMouseEvent& event) {
    if (scroll_element) {
        pressed = true;
        ScrollToPos(event.GetY());
    }
}

void ScrollInteract::OnMouseWheel(wxMouseEvent& event) {
    int amt = event.GetWheelRotation();
    double pos = ((MagicScrollbar*)GetParent())->GetPos();

    amt = (amt > 0 ? -1 : 1) * 10;

    pos += amt * 0.01;
    SetSrollPos(pos);
}

void ScrollInteract::SetScrollElem(ScrollElement* scrl_elem) {
    int elem_h = scrl_elem->GetSize().y;
    scroll_element = scrl_elem;

    lower = (GetSize().y - elem_h) / 2;
    higher = GetSize().y - lower;
}

// class MagicScrollbar

MagicScrollbar::MagicScrollbar(wxWindow* parent, const wxPoint& pos, const wxSize& size)
    : wxPanel(parent, wxID_ANY, pos, size, 0)
{
    int g_height, g_width, padding;
    wxPoint p;
    wxSize sz;

    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    //wxMemoryInputStream scrollbar_png_stream(resources_scrollbar_png, resources_scrollbar_png_len);
    wxMemoryInputStream scrollbar_png_stream = getDataStream(graphic_map["resources_scrollbar_png"]);
    scrollBarGraphics = wxImage(scrollbar_png_stream, wxBITMAP_TYPE_PNG);
    constraint_image(&scrollBarGraphics, &size);
    g_height = scrollBarGraphics.GetHeight();
    g_width = scrollBarGraphics.GetWidth();
    padding = g_width * 0.27;
    sz.x = g_width - padding * 2;
    sz.y = 0.8941606 * g_height;
    p.x = padding;
    p.y = (g_height - sz.y) / 2;

    scroll_interact = new ScrollInteract(this, &scrollBarGraphics, {0, 0}, {g_width , g_height});
    scroll_element = new ScrollElement(this, p, sz);
    scroll_element->SetHeight(0);
    scroll_element->SetPos(0.3);
    wxMemoryInputStream pixel_png_stream = getDataStream(graphic_map["resources_pixel_png"]);
    auto *bg_panel = new ImgPanel(this, &pixel_png_stream, p, sz);

    scroll_interact->SetScrollElem(scroll_element);
    scroll_content = NULL;
}

void MagicScrollbar::SetHeight(double height) {
    scroll_element->SetHeight(height);

    main_window->Redraw(this);
}

void MagicScrollbar::SetPos(double position) {
    scroll_element->SetPos(position);

    main_window->Redraw(this);
}

double MagicScrollbar::GetHeight() {
    return scroll_element->GetHeight();
}

double MagicScrollbar::GetPos() {
    return scroll_element->GetPos();
}

void MagicScrollbar::Subscribe(Scrollable* scrl_content) {
    this->scroll_content = scrl_content;
}

void MagicScrollbar::ReportScrollPos(double position) {
    if (scroll_content != NULL)
        scroll_content->SetScrollPos(position);
}

// class ModList

ModList::ModList(wxWindow* parent, const wxPoint& pos, const wxSize& size)
    : wxPanel(parent, wxID_ANY, pos, size, 0)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    content = new wxPanel(this, wxID_ANY, {0, 0}, { size.x, 32000 }, 0);
    content->SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    content->Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    Bind(wxEVT_MOUSEWHEEL, &ModList::OnMouseWheel, this);

    content_length = 0;
}

void ModList::LoadContent(std::vector<ModDataEntry> *data) {
    int next_y_pos = 0;
    const int y_size = wnd_rect.bottom * 0.05;
    const int y_setting_size = wnd_rect.bottom * 0.04;
    const int margin = y_size * 0.2;
    const int setting_margin = margin * 0.5;

    for (auto& entry : *data) {
        if (entry.disabled)
            continue;

        int total_size = entry.settings.size() * (y_setting_size + setting_margin);

        total_size += y_size;

        MagicModEnrty::CreateMagicModEntry(
            content,
            &entry,
            { 0, next_y_pos },
            { GetSize().x, total_size },
            setting_margin, y_size, y_setting_size);

        next_y_pos += margin + total_size;
    }

    display_length = content_length = next_y_pos - margin;
}

void ModList::AssociateScrollBar(MagicScrollbar* scrl_bar) {
    if (!content_length)
        return;

    int y_size = GetSize().y;
    double ratio = y_size / (double)display_length;

    scrl_bar->SetHeight(ratio);
    scrl_bar->SetPos(0);

    scrollbar = scrl_bar;
    scrollbar->Subscribe(this);
}

void ModList::AssociateFilter(MagicTextFilterCtrl* text_ctrl) {
    text_ctrl->Subscribe(this);
    filter_ctrl = text_ctrl;
}

void ModList::SetFilter(const char* filter) {
    std::string f_str(filter);
    std::vector<MagicModEnrty *> to_display;
    double ratio;

    std::transform(f_str.begin(), f_str.end(), f_str.begin(), ::tolower);

    for (auto child : content->GetChildren()) {
        auto *mod_entry = (MagicModEnrty *)child;
        auto *data = mod_entry->GetData();
        std::string str(data->name);

        mod_entry->Show(false);
        std::transform(str.begin(), str.end(), str.begin(), ::tolower);

        if (str.find(f_str) != std::string::npos)
            to_display.push_back(mod_entry);
    }

    const int margin = wnd_rect.bottom * 0.05 * 0.2;
    int next_y_pos = 0;

    for (auto child : to_display) {
        child->Show(true);
        child->SetPosition({0, next_y_pos});
        next_y_pos += margin + child->GetSize().y;
    }

    int y_size = GetSize().y;
    display_length = next_y_pos - margin;

    if (display_length > y_size)
        ratio = y_size / (double)display_length;
    else
        ratio = 1.0;

    scrollbar->SetHeight(ratio);
    scrollbar->SetPos(0);
    content->SetPosition({0, 0});

    main_window->Redraw(this);
}

void ModList::SetScrollPos(double pos) {
    if (!display_length || display_length < GetSize().y)
        return;

    int scroll_pos = wxRound(pos * (display_length - GetSize().y));

    content->SetPosition({0, -scroll_pos});
    main_window->Redraw(this);
}

void ModList::OnMouseWheel(wxMouseEvent& event) {
    if (!display_length || display_length <= GetSize().y)
        return;

    int amt = event.GetWheelRotation();
    int elem_size = content->GetChildren()[0]->GetSize().y * 1.2;
    int content_pos = content->GetPosition().y;
    int scrollable_height = display_length - GetSize().y;

    amt = (amt > 0 ? 1 : -1) * elem_size;
    content_pos += amt;

    if (content_pos > 0)
        content_pos = 0;
    if (content_pos < -scrollable_height)
        content_pos = -scrollable_height;
   
    double pos = (-content_pos) / (double)scrollable_height;

    scrollbar->SetPos(pos);
    content->SetPosition({0, content_pos});
    main_window->Redraw(this);
}

// class ModDescription

ModDescription::ModDescription(wxWindow* parent, const wxPoint& pos, const wxSize& size)
    : wxPanel(parent, wxID_ANY, pos, size, 0)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    content = new wxPanel(this, wxID_ANY, {0, 0}, { size.x, 32000 }, 0);
    content->SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    content->Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    Bind(wxEVT_MOUSEWHEEL, &ModDescription::OnMouseWheel, this);

    content_length = 0;
}

void ModDescription::LoadContent(const char *description) {
    size_t desc_len;

    if (description == NULL || (desc_len = strlen(description)) < 2) {
        display_length = content_length = GetSize().y;

        return;
    }

    const int y_size = wnd_rect.bottom * 0.05;
    const int y_setting_size = wnd_rect.bottom * 0.04;
    const int margin = y_size * 0.15;
    const int setting_margin = margin * 0.5;
    const char *line_ptr = description;
    const char *end = description + desc_len;
    const char *new_line;
    int next_y_pos = 0;

    while (line_ptr < end && NULL != (new_line = strchr(line_ptr, '\n'))) {
        int str_size = new_line - line_ptr;
        int line_size = 0;

        if (str_size > 0 && line_ptr[0] && line_ptr[0] != '\n') {
            DoubleBufferedText *text = NULL;
            char *tmp = new char[str_size + 1];

            if (line_ptr[0] == '#') {
                next_y_pos += margin * 1.5;
                memmove(tmp, line_ptr + 1, str_size - 1);
                tmp[str_size - 1] = '\0';

                text = new DoubleBufferedText(content, tmp, true, {0, next_y_pos}, {GetSize().x, 35});
                line_size = text->GetSize().y;
            }
            else {
                memmove(tmp, line_ptr, str_size);
                tmp[str_size] = '\0';

                text = new DoubleBufferedText(content, tmp, true, {0, next_y_pos}, {GetSize().x, 30});
                text->font = &font_mid;
                text->color = &color_text_desc;
                text->align = wxALIGN_LEFT | wxALIGN_CENTER_VERTICAL;
                line_size = text->GetSize().y;
            }
        }
        else {
            line_size = 10;
        }

        line_ptr = new_line + 1;
        next_y_pos += line_size + margin;
    }

    display_length = content_length = next_y_pos - margin;
}

void ModDescription::AssociateScrollBar(MagicScrollbar* scrl_bar) {
    if (!content_length)
        return;

    int y_size = GetSize().y;
    double ratio = y_size / (double)display_length;

    scrl_bar->SetHeight(ratio);
    scrl_bar->SetPos(0);

    scrollbar = scrl_bar;
    scrollbar->Subscribe(this);
}

void ModDescription::SetScrollPos(double pos) {
    if (!display_length || display_length < GetSize().y)
        return;

    int scroll_pos = wxRound(pos * (display_length - GetSize().y));

    content->SetPosition({0, -scroll_pos});
    main_window->Redraw(this);
}

void ModDescription::OnMouseWheel(wxMouseEvent& event) {
    if (!display_length || display_length <= GetSize().y)
        return;

    int amt = event.GetWheelRotation();
    int elem_size = content->GetChildren()[0]->GetSize().y * 1.2;
    int content_pos = content->GetPosition().y;
    int scrollable_height = display_length - GetSize().y;

    amt = (amt > 0 ? 1 : -1) * elem_size;
    content_pos += amt;

    if (content_pos > 0)
        content_pos = 0;
    if (content_pos < -scrollable_height)
        content_pos = -scrollable_height;
   
    double pos = (-content_pos) / (double)scrollable_height;

    scrollbar->SetPos(pos);
    content->SetPosition({0, content_pos});
    main_window->Redraw(this);
}

// class MagicTextCheckbox

MagicTextCheckbox *MagicTextCheckbox::CreateMagicTextCheckbox(wxWindow* parent, ModDataEntry *data, const wxPoint &pos, const wxSize &size) {
    MagicTextCheckbox *obj = new MagicTextCheckbox(parent, pos, size);
    obj->data = data;
    obj->checked = data->status;
    obj->InitImages(size);

    obj->Bind(wxEVT_PAINT, &MagicTextCheckbox::OnPaint, obj);
    obj->Bind(wxEVT_BUTTON, &MagicTextCheckbox::OnClick, obj);

    obj->font = obj->font_normal = &font_text;
    obj->font_highlight = &font_btn;

    return obj;
}

MagicTextCheckbox::MagicTextCheckbox(wxWindow* parent, const wxPoint& pos, const wxSize& size)
    : MagicButton(parent, pos, size)
{
    checked = false;
}

void MagicTextCheckbox::InitImages(const wxSize& size) {
    //wxMemoryInputStream checkbox_png_stream(resources_checkbox_png, resources_checkbox_png_len);
    wxMemoryInputStream checkbox_png_stream = getDataStream(graphic_map["resources_checkbox_png"]);
    checkbox = wxImage(checkbox_png_stream, wxBITMAP_TYPE_PNG);
    constraint_image(&checkbox, &size);

    //wxMemoryInputStream checkbox_select_png_stream(resources_checkbox_select_png, resources_checkbox_select_png_len);
    wxMemoryInputStream checkbox_select_png_stream = getDataStream(graphic_map["resources_checkbox_select_png"]);
    checkbox_select = wxImage(checkbox_select_png_stream, wxBITMAP_TYPE_PNG);
    constraint_image(&checkbox_select, &size);
}

void MagicTextCheckbox::OnPaint(wxPaintEvent& event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);
    int checkbox_width = checkbox.GetWidth() * 1.25;

    SetFont(*font);

    if (checked)
        dc.DrawBitmap(checkbox_select, 0, 0);
    else
        dc.DrawBitmap(checkbox, 0, 0);

    dc.SetFont(*font);
    dc.SetTextForeground(*color);
    dc.DrawLabel(data->name, { checkbox_width, 0, GetSize().x - checkbox_width, GetSize().y}, wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT);
}

void MagicTextCheckbox::OnClick(wxEvent& event) {
    checked = !checked;
    data->status = checked;
}

// class MagicModSetting

MagicModSetting::MagicModSetting(wxWindow *parent, const wxPoint &pos, const wxSize &size, std::pair<const std::string, std::string> *setting)
    : wxPanel(parent, wxID_ANY, pos, size)
{
    this->setting = setting;

    SetBackgroundStyle(wxBG_STYLE_CUSTOM);

    Bind(wxEVT_PAINT, &MagicModSetting::OnPaint, this);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);

    const int label_gap = size.x * 0.01;
    const int label_offset = size.x * 0.14;
    const int label_end = (size.x - label_offset) * 0.6;


    std::function<bool(const char *)> functor = [this](const char *value) {
        bool ret;

        if ((ret = validate_value(&(this->setting->first), value)))
            this->setting->second = value;

        return ret;
    };

    MagicModSettingLabel::CreateMagicModSettingLabel(this, &setting->first, { label_offset, 0 }, { label_end - label_offset, size.y });
    auto *textCtrl = new MagicTextSettingCtrl(this, { label_end + label_gap, 0 }, { size.x - label_end - label_gap, size.y }, setting->second.c_str(), functor);
}

void MagicModSetting::OnPaint(wxPaintEvent &event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);
}

// class MagicModSettingLabel

MagicModSettingLabel *MagicModSettingLabel::CreateMagicModSettingLabel(wxWindow *parent, const std::string *setting_name, const wxPoint &pos, const wxSize &size) {
    MagicModSettingLabel *obj = new MagicModSettingLabel(parent, pos, size, setting_name);

    obj->font = obj->font_normal = &font_small;
    obj->font_highlight = &font_small;

    return obj;
}

MagicModSettingLabel::MagicModSettingLabel(wxWindow *parent, const wxPoint &pos, const wxSize &size, const std::string *setting_name)
    : MagicButton(parent, pos, size)
{
    this->setting_name = setting_name;
    InitImages(size);

    Bind(wxEVT_PAINT, &MagicModSettingLabel::OnPaint, this);
    Bind(wxEVT_BUTTON, &MagicModSettingLabel::OnClick, this);
}

void MagicModSettingLabel::OnPaint(wxPaintEvent &event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);
    wxSize label_size = GetSize();
    wxSize img_size = qustionmark.GetSize();

    SetFont(*font);

    dc.SetFont(*font);
    dc.SetTextForeground(*color);
    dc.DrawLabel(*setting_name, { 0, 0, label_size.x, label_size.y }, wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT);
    dc.DrawBitmap(qustionmark, label_size.x - img_size.x, (label_size.y - img_size.y) / 2.0);
}

void MagicModSettingLabel::OnClick(wxEvent &event) {
    // Ideally here we start listening to key presses
    //     on keyboard and on gamepad
    //     in order to auto-update the text field
    //     i dont wanna do it maaaaaan
    //     this would take Keyboard listening and XBox controller button listening though winapi
    display_setting_help(this, setting_name);
}

void MagicModSettingLabel::InitImages(const wxSize &size) {
    wxSize img_size = size / 1.5;

    qustionmark = image_from_resource("resources_questionmark_png");
    constraint_image(&qustionmark, &img_size);
}

// class MagicModDescButton

MagicModDescButton *MagicModDescButton::CreateMagicModDescButton(wxWindow *parent, const std::string &name, const wxPoint &pos, const wxSize &size) {
    MagicModDescButton *obj = new MagicModDescButton(parent, pos, size);
    obj->name = name;

    return obj;
}

MagicModDescButton::MagicModDescButton(wxWindow *parent, const wxPoint &pos, const wxSize &size)
    : MagicButton(parent, pos, size)
{
    InitImages(size);

    Bind(wxEVT_PAINT, &MagicModDescButton::OnPaint, this);
    Bind(wxEVT_BUTTON, &MagicModDescButton::OnClick, this);
}

void MagicModDescButton::OnPaint(wxPaintEvent &event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);

    dc.DrawBitmap(qustionmark, 0, 0);
}

void MagicModDescButton::OnClick(wxEvent &event) {
    const char *mod_dec = get_mod_description(&name);
    main_window->InitModDescPage(name.c_str(), mod_dec);
}

void MagicModDescButton::InitImages(const wxSize &size) {
    qustionmark = image_from_resource("resources_questionmark_png");
    constraint_image(&qustionmark, &size);
}

// class MagicModEnrty

MagicModEnrty *MagicModEnrty::CreateMagicModEntry(wxWindow* parent, ModDataEntry* data, const wxPoint& pos, const wxSize& size, const int margin, const int h_checkbox, const int h_setting) {
    MagicModEnrty *obj = new MagicModEnrty(parent, pos, size);
    int next_y_pos = h_checkbox + margin;
    int h_mod_desc_btn = h_checkbox / 1.5;

    obj->data = data;

    MagicModDescButton::CreateMagicModDescButton(obj, data->name, { size.x - h_mod_desc_btn, (h_checkbox - h_mod_desc_btn) / 2 }, { h_mod_desc_btn, h_mod_desc_btn });
    MagicTextCheckbox::CreateMagicTextCheckbox(obj, data, { 0, 0 }, { size.x, h_checkbox });
    
    new ImgPanel(
        obj,
        "resources_hor_bar_png",
        wxPoint(h_checkbox / 2.0, h_checkbox * 0.02),
        wxSize(size.x - h_checkbox, h_checkbox),
        true
    );

    for (auto &setting : data->settings) {
        new MagicModSetting(obj, { 0, next_y_pos }, { size.x, h_setting }, &setting);
        next_y_pos += h_setting + margin;
    }

    return obj;
}

MagicModEnrty::MagicModEnrty(wxWindow* parent, const wxPoint& pos, const wxSize& size)
    : wxPanel(parent, wxID_ANY, pos, size, 0)
{
    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    Bind(wxEVT_PAINT, &MagicModEnrty::OnPaint, this);
    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);
}

void MagicModEnrty::OnPaint(wxPaintEvent& event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);
}

ModDataEntry *MagicModEnrty::GetData() {
    return data;
}

// calss CustomCursor

CustomCursor::CustomCursor(wxWindow *parent, const char *file_name, const wxPoint &pos, const wxSize &size, int cursor_size)
    : ImgPanel(parent, file_name, pos, size)
{
    resize_image(&img, { cursor_size, cursor_size });
    Bind(wxEVT_PAINT, &CustomCursor::OnPaint, this);

    cursor_pos = { pos.x - cursor_size - 1, pos.y - cursor_size - 1 };

    Raise();
    SetWindowLong((HWND)this->GetHandle(), GWL_EXSTYLE, GetWindowLong((HWND)this->GetHandle(), GWL_EXSTYLE) | WS_EX_TRANSPARENT | WS_EX_LAYERED);
}

WXLRESULT CustomCursor::MSWWindowProc(WXUINT message, WXWPARAM wParam, WXLPARAM lParam) {
    if (message == WM_NCHITTEST)
    {
        return HTTRANSPARENT;
    }

    return ImgPanel::MSWWindowProc(message, wParam, lParam);
}

void CustomCursor::SetCursorPos(wxPoint pos) {
    cursor_pos = pos;
    main_window->Redraw(this);
}

void CustomCursor::OnPaint(wxPaintEvent &event) {
    setDoubleBuffered(this);
    wxPaintDC dc(this);

    dc.DrawBitmap(img, cursor_pos);
}

// class ModSettingsFrame

ModSettingsFrame::ModSettingsFrame()
    : wxFrame(nullptr, wxID_ANY, "Magicka 2 Mod Settings", {wnd_rect.left, wnd_rect.top}, wxSize(wnd_rect.right, wnd_rect.bottom), 0)
{
    HINSTANCE hInstance = GetModuleHandle(NULL);
    HICON hMyIcon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_ICON1));
    HWND hwnd = (HWND)this->GetHandle();

    SetWindowLong(hwnd, GWL_EXSTYLE, WS_EX_TOPMOST);
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);

    SendMessage(hwnd, WM_SETICON, ICON_SMALL, (LPARAM)hMyIcon);
    SendMessage(hwnd, WM_SETICON, ICON_BIG, (LPARAM)hMyIcon);

    SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    main_window = this;
    inner_w = wnd_rect.right - 2;
    inner_h = wnd_rect.bottom - 2;
    padding = inner_w / 35;

    Bind(wxEVT_ERASE_BACKGROUND, erase_bg_handler);
    Bind(wxEVT_PAINT, &ModSettingsFrame::OnPaint, this);

    wxMemoryInputStream bg_fhd_png_stream = getDataStream(graphic_map["resources_bg_fhd_png"]);
    container = new ImgPanel(
        this,
        &bg_fhd_png_stream,
        wxPoint(0, 0),
        wxSize(inner_w, inner_h)
    );
    settings_container = new wxPanel(
        container,
        wxID_ANY,
        wxPoint(0, 0),
        wxSize(inner_w, inner_h)
    );
    settings_container->SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    description_container = new wxPanel(
        container,
        wxID_ANY,
        wxPoint(0, 0),
        wxSize(inner_w, inner_h)
    );
    description_container->SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    description_container->Show(false);

    InitMainPage();

    if (mouse_hook != NULL) {
        this->SetCursor(cursor_blank);
        int cursor_size = (inner_w > inner_h ? inner_h : inner_w) * 0.07;

        cursor = new CustomCursor(
            container,
            "resources_cursor_png",
            wxPoint(0, 0),
            wxSize(inner_w, inner_h),
            cursor_size);
    }
    else
        cursor = NULL;
}

void ModSettingsFrame::InitModDescPage(const char *mod_name, const char *mod_desc_text) {
    if (mod_desc_text == NULL)
        return;
    else
        cur_mod_desc = mod_desc_text;

    int tmp_x, tmp_y, next_y_pos = 0;
    wxSize tmp;
    auto *bg_panel = description_container;

    wxMemoryInputStream elem_bg_r_png_stream = getDataStream(graphic_map["resources_elem_bg_r_png"]);
    auto *filter_panel = new ImgPanel(
        bg_panel,
        &elem_bg_r_png_stream,
        wxPoint(padding, next_y_pos + padding),
        wxSize(inner_w - padding * 2, inner_w / 6));

    tmp_x = filter_panel->GetSize().x - padding * 2;
    tmp_y = filter_panel->GetSize().y - padding * 2;

    new DoubleBufferedText(filter_panel, mod_name, false, {padding, padding}, {tmp_x, tmp_y});

    next_y_pos += filter_panel->GetPosition().y + filter_panel->GetSize().y;

    wxMemoryInputStream elem_bg_s_png_stream = getDataStream(graphic_map["resources_elem_bg_s_png"]);
    auto* mods_panel = new ImgPanel(
        bg_panel,
        &elem_bg_s_png_stream,
        wxPoint(padding * 4.5, next_y_pos + padding),
        wxSize(inner_w - padding * 5.5, inner_h - next_y_pos - padding * 9.6));

    auto* scrollbar = new MagicScrollbar(
        bg_panel,
        wxPoint(padding * 1.5, next_y_pos + padding),
        wxSize(padding * 4, mods_panel->GetSize().y));

    auto *mod_desc = new ModDescription(
        mods_panel,
        {padding, padding},
        {mods_panel->GetSize().x - padding * 2, mods_panel->GetSize().y - padding * 2});
    mod_desc->LoadContent(mod_desc_text);
    mod_desc->AssociateScrollBar(scrollbar);

    next_y_pos = mods_panel->GetPosition().y + mods_panel->GetSize().y + padding * 2.6;

    auto* sponsor_text = new DoubleBufferedText(
        bg_panel,
        "Magicka College is \"dead\"",
        false,
        wxPoint(padding * 1.1, next_y_pos - padding * 3),
        wxSize(tmp_x / 1.5, padding * 4));
    sponsor_text->drop_shadow = true;
    sponsor_text->color = &color_sponsor;

    auto* join_btn = MagicButton::CreateMagicButton(
        bg_panel,
        "My Website",
        open_sponsor_link,
        wxPoint(tmp_x * 0.675, next_y_pos - padding * 3),
        wxSize(inner_w / 2 - padding * 2.5, padding * 4));
    join_btn->SetColors(&color_sponsor, &color_sponsor_h);
    join_btn->drawGUI = false;
    join_btn->drop_shadow = true;

    tmp_x = inner_w / 2 - padding * 2.5;
    auto* close_btn = MagicButton::CreateMagicButton(
        bg_panel,
        "Back",
        [] {main_window->BackToModSettings();},
        wxPoint(padding * 1.5, next_y_pos + padding),
        wxSize(tmp_x, padding * 4)
    );
    auto* copy_btn = MagicButton::CreateMagicButton(
        bg_panel,
        "Copy",
        [] {
            const char *txt = main_window->cur_mod_desc;
            if(txt == NULL || !OpenClipboard(NULL))
                return;

            HGLOBAL clipbuffer;
            char * buffer;

            EmptyClipboard();

            clipbuffer = GlobalAlloc(GMEM_DDESHARE, strlen(txt)+1);
            buffer = (char*)GlobalLock(clipbuffer);
            strcpy(buffer, LPCSTR(txt));

            GlobalUnlock(clipbuffer);
            SetClipboardData(CF_TEXT, clipbuffer);

            CloseClipboard();
        },
        wxPoint(close_btn->GetPosition().x + close_btn->GetSize().x + padding * 2, next_y_pos + padding),
        wxSize(tmp_x, padding * 4)
    );

    settings_container->Show(false);
    bg_panel->Show(true);
}

void ModSettingsFrame::BackToModSettings() {
    description_container->Destroy();
    settings_container->Show(true);
    description_container = new wxPanel(
        container,
        wxID_ANY,
        wxPoint(0, 0),
        wxSize(inner_w, inner_h)
    );
    description_container->SetBackgroundStyle(wxBG_STYLE_CUSTOM);
    description_container->Show(false);
}

void ModSettingsFrame::InitMainPage() {
    int tmp_x, tmp_y, next_y_pos = 0;
    wxSize tmp;
    auto *bg_panel = settings_container;

    wxMemoryInputStream elem_bg_r_png_stream = getDataStream(graphic_map["resources_elem_bg_r_png"]);
    auto *filter_panel = new ImgPanel(
        bg_panel,
        &elem_bg_r_png_stream,
        wxPoint(padding, next_y_pos + padding),
        wxSize(inner_w - padding * 2, inner_w / 6));

    tmp_x = filter_panel->GetSize().x - padding * 2;
    tmp_y = filter_panel->GetSize().y - padding * 2;

    new DoubleBufferedText(filter_panel, "Filter mods by name:", false, {padding, padding}, {tmp_x / 2, tmp_y});
    auto *filter_ctrl = new MagicTextFilterCtrl(filter_panel, "filter", {padding + tmp_x / 2, padding}, {tmp_x / 2, tmp_y});

    next_y_pos += filter_panel->GetPosition().y + filter_panel->GetSize().y;

    wxMemoryInputStream elem_bg_s_png_stream = getDataStream(graphic_map["resources_elem_bg_s_png"]);
    auto* mods_panel = new ImgPanel(
        bg_panel,
        &elem_bg_s_png_stream,
        wxPoint(padding * 4.5, next_y_pos + padding),
        wxSize(inner_w - padding * 5.5, inner_h - next_y_pos - padding * 9.6));

    auto* scrollbar = new MagicScrollbar(
        bg_panel,
        wxPoint(padding * 1.5, next_y_pos + padding),
        wxSize(padding * 4, mods_panel->GetSize().y));

    auto *mod_list = new ModList(
        mods_panel,
        {padding, padding},
        {mods_panel->GetSize().x - padding * 2, mods_panel->GetSize().y - padding * 2});
    mod_list->LoadContent(mods_data);
    mod_list->AssociateScrollBar(scrollbar);
    mod_list->AssociateFilter(filter_ctrl);

    next_y_pos = mods_panel->GetPosition().y + mods_panel->GetSize().y + padding * 2.6;

    auto* sponsor_text = new DoubleBufferedText(
        bg_panel,
        "Magicka College is \"dead\"",
        false,
        wxPoint(padding * 1.4, next_y_pos - padding * 3),
        wxSize(tmp_x / 1.5, padding * 4));
    sponsor_text->drop_shadow = true;
    sponsor_text->color = &color_sponsor;

    auto* join_btn = MagicButton::CreateMagicButton(
        bg_panel,
        "My Website",
        open_sponsor_link,
        wxPoint(tmp_x * 0.675, next_y_pos - padding * 3),
        wxSize(inner_w / 2 - padding * 2.5, padding * 4));
    join_btn->SetColors(&color_sponsor, &color_sponsor_h);
    join_btn->drawGUI = false;
    join_btn->drop_shadow = true;

    auto* close_btn = MagicButton::CreateMagicButton(
        bg_panel,
        "Close",
        close_program,
        wxPoint(padding * 1.5, next_y_pos + padding),
        wxSize(inner_w / 2 - padding * 2.5, padding * 4));
    auto* apply_btn = MagicButton::CreateMagicButton(
        bg_panel,
        "Save",
        save_mod_settings_wrapper,
        wxPoint(close_btn->GetPosition().x + close_btn->GetSize().x + padding * 2, next_y_pos + padding),
        wxSize(inner_w / 2 - padding * 2.5, padding * 4));
}

void ModSettingsFrame::UpdateCustomCursorPos() {
    if (program_closing || cursor == NULL)
        return;

    wxPoint mouse_pos = wxGetMousePosition();
    wxPoint wnd_pos = GetScreenPosition();
    wxSize wnd_size = GetSize();

    mouse_pos.x = mouse_pos.x - wnd_pos.x;
    mouse_pos.y = mouse_pos.y - wnd_pos.y;

    if (mouse_pos.x < 0 || mouse_pos.x > wnd_size.x)
        return;

    if (mouse_pos.y < 0 || mouse_pos.y > wnd_size.y)
        return;

    cursor->SetCursorPos(mouse_pos);
}

void ModSettingsFrame::OnPaint(wxPaintEvent& event) {
    //setDoubleBuffered(this); THIS CAUSES FLICKER
    event.Skip();
}

void ModSettingsFrame::Redraw(wxWindow *wnd) {
    if (program_closing)
        return;

    wxRect rect = wnd->GetRect();
    RefreshRect(wnd->GetRect(), false);
}

// main function

static bool focus_already_opened(DWORD pid) {
    DWORD opened_exe_pid;
    RECT opened_exe_rect;
    HWND opened_exe_hwnd;

    if ((opened_exe_hwnd = find_hwnd_by_pid(opened_exe_pid)) == NULL) {
        const auto explorer = OpenProcess(PROCESS_TERMINATE, false, pid);
        TerminateProcess(explorer, 1);
        CloseHandle(explorer);

        return false;
    }

    debug_print("found opened hwnd\n");

    //set up a generic keyboard event
    INPUT keyInput;
    keyInput.type = INPUT_KEYBOARD;
    keyInput.ki.wScan = 0; //hardware scan code for key
    keyInput.ki.time = 0;
    keyInput.ki.dwExtraInfo = 0;

    //set focus to the hWnd (sending Alt allows to bypass limitation)
    keyInput.ki.wVk = VK_MENU;
    keyInput.ki.dwFlags = 0;   //0 for key press
    SendInput(1, &keyInput, sizeof(INPUT));

    SetForegroundWindow(opened_exe_hwnd); //sets the focus 

    keyInput.ki.wVk = VK_MENU;
    keyInput.ki.dwFlags = KEYEVENTF_KEYUP;  //for key release
    SendInput(1, &keyInput, sizeof(INPUT));

    return true;
}

void try_set_new_wnd_size(RECT rect) {
    int height, width;
    RECT new_rect;

    new_rect.left = (rect.right + rect.left) / 2;
    new_rect.top = (rect.bottom - rect.top) / 2;

    height = (rect.bottom - rect.top) * 4 / 5;
    width = height / 16 * 9;

    new_rect.left -= width / 2;
    new_rect.top -= height / 2;
    new_rect.right = width;
    new_rect.bottom = height;

    if (new_rect.right > wnd_rect.right && new_rect.bottom > wnd_rect.bottom)
        wnd_rect = new_rect;
}

#if defined(DEBUG) || defined(_DEBUG)
int wmain() {
#else
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow) {
#endif // DEBUG
    DWORD opened_exe_pid;

    if(0 != (opened_exe_pid = find_pid(L"m2_mod_settings.exe"))) {
        debug_print("found an open m2_mod_settings.exe\n");

        if (focus_already_opened(opened_exe_pid))
            return 2;
    }

    ModSettings* pApp;
    DWORD magicka_pid;
    RECT m2_wnd_rect;

    WCHAR w_file_name[MAX_PATH];
    char file_name[MAX_PATH];

    debug_print("shit 1\n");

    GetModuleFileNameW(NULL, w_file_name, MAX_PATH);
    size_t str_size = wcstombs(file_name, w_file_name, MAX_PATH);
    file_name[str_size] = '\0';

    debug_print("shit 2\n");

    std::filesystem::path exec_path(file_name);
    std::filesystem::path data_path = exec_path.parent_path();
    data_path.append("data.ifa");

    debug_print("shit 3\n");

    setup_file_paths();

    if (!config_file_exists()) {
        MessageBoxA(NULL, "Could not find mods configuration file.\nMake sure to launch the game at least once with mods installed.", "File not found", MB_ICONERROR);
        return 1;
    }

    debug_print("shit 4\n");

    parse_file_mods_settings(true, true);

    debug_print("shit 5\n");

    SetProcessDPIAware();
    char msg[1024];
    HDC hdc = GetDC(NULL);
    double scaling = GetDeviceCaps(hdc, LOGPIXELSX) / 96.0;
    if (abs(scaling) < 0.25)
        scaling = 1.0;
    if (scaling < 0.0)
        scaling *= -1;

    HMODULE hMod = GetModuleHandleA(NULL);
    DWORD idThread = GetCurrentThreadId();
    if ((mouse_hook = SetWindowsHookExA(WH_MOUSE, MouseHookEvent, hMod, idThread)) == NULL) {
        printf("Failed to create mouse hook: %lu\n", GetLastError());
        printf("hMod :: 0x%lx\n", (unsigned long)hMod);
        printf("idThread :: 0x%lx\n", idThread);
    }

    debug_print("shit 6\n");

    mods_data = get_mod_config_entries();
    parse_indexed_file_amalgamation(&data_path);

    debug_print("shit 7\n");

    int width = GetSystemMetrics(SM_CXSCREEN);
    int height = GetSystemMetrics(SM_CYSCREEN);

    try_set_new_wnd_size({0, 0, width, height});

    if (0 != (magicka_pid = find_pid(L"Magicka2.exe"))) {
        m2_hwnd = find_hwnd_by_pid(magicka_pid);

        if (m2_hwnd && GetWindowRect(m2_hwnd, &m2_wnd_rect)) {
            try_set_new_wnd_size(m2_wnd_rect);
        }
    }

    debug_print("shit 8\n");

    load_font();
    const float font_specific_mult = 0.8;
    font_btn = wxFont((wnd_rect.bottom * 0.03 * font_specific_mult) / scaling, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_EXTRALIGHT, false, "Vinque Rg");
    font_big = wxFont((wnd_rect.bottom * 0.035 * font_specific_mult) / scaling, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_EXTRALIGHT, false, "Vinque Rg");
    font_text = wxFont((wnd_rect.bottom * 0.025 * font_specific_mult) / scaling, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_EXTRALIGHT, false, "Vinque Rg");
    font_mid = wxFont((wnd_rect.bottom * 0.020 * font_specific_mult) / scaling, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_EXTRALIGHT, false, "Vinque Rg");
    font_small = wxFont((wnd_rect.bottom * 0.017 * font_specific_mult) / scaling, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_EXTRALIGHT, false, "Vinque Rg");

    debug_print("shit 9\n");

    wxSystemOptions::SetOption("msw.window.no-clip-children", 1);
    wxImage::AddHandler(new wxPNGHandler);

    debug_print("shit 10\n");

    wxMemoryInputStream stream = getDataStream(graphic_map["resources_pixel_png"]);
    auto img = wxImage(stream, wxBITMAP_TYPE_PNG);
    cursor_blank = wxCursor(img);

    debug_print("shit 11\n");

    pApp = new ModSettings();
    wxApp::SetInstance(pApp);

    debug_print("shit 12\n");

    int ret = wxEntry(0, NULL);

    if (m2_hwnd != NULL) {
        PostMessage(m2_hwnd, WM_SYSCOMMAND, SC_RESTORE, 0);
        SetFocus(m2_hwnd);
    }

    return ret;
}
