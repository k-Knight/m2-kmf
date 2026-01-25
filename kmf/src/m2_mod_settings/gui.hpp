#ifndef SETTINGS_MENU_GUI
#define SETTINGS_MENU_GUI

#include <wx/wx.h>
#include <wx/sysopt.h>
#include <wx/dcbuffer.h>
#include <wx/graphics.h>
#include <wx/mstream.h>
#include <kmf_util.hpp>

class ModSettings : public wxApp {
public:
    bool OnInit() override;
};

class ImgPanel : public wxPanel {
public:
    ImgPanel(wxWindow *parent, const char *file_name, const wxPoint &pos, const wxSize &size, const bool constraint = false, long style = wxTAB_TRAVERSAL);
    ImgPanel(wxWindow *parent, wxInputStream *stream, const wxPoint &pos, const wxSize &size, const bool constraint = false, long style = wxTAB_TRAVERSAL);
    ImgPanel(wxWindow *parent, wxImage *img, const wxPoint &pos, const wxSize &size, const bool constraint = false, long style = wxTAB_TRAVERSAL);
protected:
    wxImage img;
    bool constraint;

    virtual void Setup();
    virtual void OnPaint(wxPaintEvent &event);
};

class CustomCursor : public ImgPanel {
public:
    CustomCursor(wxWindow *parent, const char *file_name, const wxPoint &pos, const wxSize &size, int cursor_size);
    void SetCursorPos(wxPoint pos);

protected:
    wxPoint cursor_pos;

    virtual void OnPaint(wxPaintEvent &event);
    virtual WXLRESULT MSWWindowProc(WXUINT message, WXWPARAM wParam, WXLPARAM lParam);
};

class ModSettingsFrame : public wxFrame {
public:
    ModSettingsFrame();
    void Redraw(wxWindow* wnd);
    void UpdateCustomCursorPos();
    void BackToModSettings();
    void InitMainPage();
    void InitModDescPage(const char *mod_name, const char *mod_desc_text);

    const char *cur_mod_desc = NULL;

protected:
    CustomCursor *cursor;
    int inner_w, inner_h, padding;
    wxWindow *settings_container;
    wxWindow *description_container;
    wxWindow *container;

    void OnPaint(wxPaintEvent &event);
};

class MagicButton : public wxWindow {
public:
    volatile bool drawGUI;
    volatile bool drop_shadow;

    void SetColors(wxColour *normal, wxColour *highlight);
    static MagicButton *CreateMagicButton(wxWindow* parent, const char* label, void (*callback)(void), const wxPoint& pos, const wxSize& size);
protected:
    wxImage img_bg, img_l, img_r;
    wxColour *color, *normal_color, *highlight_color;
    wxFont *font, *font_normal, *font_highlight;
    const char* label;
    void (*callback)(void);
    bool can_click, click_registered;
    std::vector<wxRect> outline_positions;

    MagicButton(wxWindow* parent, const wxPoint& pos, const wxSize& size);
    virtual void InitImages(const wxSize& size);
    virtual void OnPaint(wxPaintEvent& event);
    virtual void OnMouseEnter(wxEvent& event);
    virtual void OnMouseLeave(wxEvent &event);
    virtual void OnMouseDown(wxEvent &event);
    virtual void OnMouseUp(wxEvent& event);
    virtual void OnClick(wxEvent& event);
};

class DoubleBufferedText : public wxPanel {
public:
    wxFont *font;
    volatile bool drop_shadow;
    wxColour *color;
    int align;

    DoubleBufferedText(wxWindow* parent, const char* label, bool free_label, const wxPoint& pos, const wxSize& size);
    ~DoubleBufferedText();

protected:
    const char *label;
    bool free_label;
    std::vector<wxRect> outline_positions;

    void OnPaint(wxPaintEvent& event);
};

class DoubleBufferedTextCtrl : public wxTextCtrl {
public:
    DoubleBufferedTextCtrl(wxWindow *parent, const wxPoint &pos, const wxSize &size, wxFont *font, wxColour *colour, std::function<void(const char *)> callback);
    wxFont* font;
    wxColour *colour;
    wxImage selection_image;

protected:
    std::function<void(const char *)> callback;
    volatile int prev_from = 0, prev_to = 0;

    virtual void OnPaint(wxPaintEvent &event);
    virtual void OnTextChanged(wxCommandEvent &event);
    virtual void OnKillFocus(wxFocusEvent &event);
};

class Filterable {
public:
    virtual void SetFilter(const char* filter) = 0;
};

class MagicTextFilterCtrl : public ImgPanel {
public:
    MagicTextFilterCtrl(wxWindow *parent, const char *label, const wxPoint &pos, const wxSize &size);
    void Subscribe(Filterable *filterable);
    void SetFilter(const char *filter);

protected:
    DoubleBufferedTextCtrl *textCtrl;
    wxPanel *bounding_box;
    Filterable* filter_elem;
};

class MagicTextSettingCtrl : public ImgPanel {
public:
    MagicTextSettingCtrl(wxWindow *parent, const wxPoint &pos, const wxSize &size, const char *cur_value, std::function<bool(const char *)> callback);
    void SetValue(const char *value);

protected:
    DoubleBufferedTextCtrl *textCtrl;
    wxPanel *bounding_box;
    std::function<bool(const char *)> callback;
};

class Scrollable {
public:
    virtual void SetScrollPos(double pos) = 0;
};

class ScrollElement : public wxPanel {
public:
    ScrollElement(wxWindow* parent, const wxPoint& pos, const wxSize& size);
    void SetHeight(double height);
    void SetPos(double position);
    double GetHeight();
    double GetPos();

protected:
    wxImage img_top, img_bottom;
    wxButton *btn;
    double scrl_height;
    double scrl_pos;

    void OnPaint(wxPaintEvent& event);
};

class ScrollInteract : public ImgPanel {
public:
    ScrollInteract(wxWindow* parent, wxImage *img, const wxPoint& pos, const wxSize& size);
    void SetScrollElem(ScrollElement* scrl_elem);

protected:
    ScrollElement *scroll_element;
    bool pressed;
    int lower, higher;

    void ScrollToPos(int y);
    void SetSrollPos(double pos);
    void OnLeftUp(wxMouseEvent& event);
    void OnMouseMove(wxMouseEvent& event);
    void OnLeftDown(wxMouseEvent& event);
    void OnMouseWheel(wxMouseEvent& event);
    void OnMouseLeave(wxEvent& event);
};

class MagicScrollbar : public wxPanel {
public:
    MagicScrollbar(wxWindow* parent, const wxPoint& pos, const wxSize& size);
    void SetHeight(double height);
    void SetPos(double position);
    double GetHeight();
    double GetPos();
    void Subscribe(Scrollable* scrl_content);
    void ReportScrollPos(double position);

protected:
    wxImage scrollBarGraphics;
    ScrollElement *scroll_element;
    ScrollInteract *scroll_interact;
    Scrollable *scroll_content;
};

class MagicTextCheckbox : public MagicButton {
public:
    static MagicTextCheckbox *CreateMagicTextCheckbox(wxWindow *parent, ModDataEntry *data, const wxPoint &pos, const wxSize &size);

protected:
    bool checked;
    wxImage checkbox, checkbox_select;
    ModDataEntry *data;

    MagicTextCheckbox(wxWindow *parent, const wxPoint &pos, const wxSize &size);
    virtual void InitImages(const wxSize &size);
    virtual void OnPaint(wxPaintEvent &event);
    virtual void OnClick(wxEvent &event);
};

class MagicModEnrty : public wxPanel {
public:
    static MagicModEnrty *CreateMagicModEntry(wxWindow *parent, ModDataEntry *data, const wxPoint &pos, const wxSize &size, const int margin, const int h_checkbox, const int h_setting);
    ModDataEntry *GetData();

protected:
    ModDataEntry *data;

    MagicModEnrty(wxWindow *parent, const wxPoint &pos, const wxSize &size);
    virtual void OnPaint(wxPaintEvent &event);
};

class MagicModSetting : public wxPanel {
public:
    MagicModSetting(wxWindow *parent, const wxPoint &pos, const wxSize &size, std::pair<const std::string, std::string> *setting);

protected:
    std::pair<const std::string, std::string> *setting;

    virtual void OnPaint(wxPaintEvent &event);
};

class MagicModSettingLabel : public MagicButton {
public:
    static MagicModSettingLabel *CreateMagicModSettingLabel(wxWindow *parent, const std::string *setting_name, const wxPoint &pos, const wxSize &size);

protected:
    const std::string *setting_name;
    wxImage qustionmark;

    MagicModSettingLabel(wxWindow *parent, const wxPoint &pos, const wxSize &size, const std::string *setting_name);
    virtual void InitImages(const wxSize& size);
    virtual void OnPaint(wxPaintEvent &event);
    virtual void OnClick(wxEvent& event);
};

class MagicModDescButton : public MagicButton {
public:
    static MagicModDescButton *CreateMagicModDescButton(wxWindow *parent, const std::string &name, const wxPoint &pos, const wxSize &size);

protected:
    wxImage qustionmark;
    std::string name;

    MagicModDescButton(wxWindow *parent, const wxPoint &pos, const wxSize &size);
    virtual void InitImages(const wxSize& size);
    virtual void OnPaint(wxPaintEvent &event);
    virtual void OnClick(wxEvent& event);
};


class ModList : public wxPanel, public Scrollable, public Filterable {
public:
    ModList(wxWindow* parent, const wxPoint& pos, const wxSize& size);

    void LoadContent(std::vector<ModDataEntry> *data);
    void AssociateScrollBar(MagicScrollbar *scrl_bar);
    void AssociateFilter(MagicTextFilterCtrl *text_ctrl);
    void SetScrollPos(double pos);
    void SetFilter(const char* filter);

protected:
    wxPanel *content;
    int content_length, display_length;
    MagicScrollbar *scrollbar;
    MagicTextFilterCtrl *filter_ctrl;

    void OnMouseWheel(wxMouseEvent& event);
};

class ModDescription : public wxPanel, public Scrollable {
public:
    ModDescription(wxWindow* parent, const wxPoint& pos, const wxSize& size);

    void LoadContent(const char *description);
    void AssociateScrollBar(MagicScrollbar *scrl_bar);
    void SetScrollPos(double pos);

protected:
    wxPanel *content;
    int content_length, display_length;
    MagicScrollbar *scrollbar;

    void OnMouseWheel(wxMouseEvent& event);
};

wxColour color_shadow    = {   0,   0,   0 };
wxColour color_scroll    = { 255, 229, 179 };
wxColour color_text      = { 245, 200, 155 };
wxColour color_text_desc = { 245, 235, 210 };
wxColour color_error     = { 245,  50,   0 };
wxColour color_sponsor   = { 155, 242, 203 };
wxColour color_sponsor_h = { 209, 255, 234 };
wxColour color_highlight = { 252, 238, 225 };

#endif //SETTINGS_MENU_GUI
