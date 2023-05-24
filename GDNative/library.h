#ifndef GDNATIVE_LIBRARY_H
#define GDNATIVE_LIBRARY_H

#include <Godot.hpp>
#include <RichTextLabel.hpp>

namespace godot {

    class GDNShell : public RichTextLabel {
        GODOT_CLASS(GDNShell, RichTextLabel)

    private:
        float time_passed;
        String APP_NAME = "Console";
        Array LOG;

    public:
        static void _register_methods();

        GDNShell();
        ~GDNShell();

        void _init(); // our initializer called by Godot

        void _process(float delta);
    };

}

#endif //GDNATIVE_LIBRARY_H
