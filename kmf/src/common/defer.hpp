template<typename F>
struct ScopeGuard {
    ScopeGuard(F fn) : fn(std::move(fn)) {}

    void Free() {
        if (!released)
            fn();

        released = true;
    }

    F Take() {
        released = true;

        return std::move(fn);
    }

    ~ScopeGuard() {
        if (!released)
            fn();
    }

    F fn;
    bool released = false;
};

#define __DEFER(F, L) auto _defered_##L = ScopeGuard(F);
#define _DEFER(F, L) __DEFER(F, L)
#define DEFER(F) _DEFER(F, __LINE__)
