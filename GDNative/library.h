#ifndef GDNATIVE_LIBRARY_H
#define GDNATIVE_LIBRARY_H

#include <Godot.hpp>
#include <Node.hpp>

namespace godot {

    class GDNShell : public Node {
        GODOT_CLASS(GDNShell, Node)

    private:
        float time_passed;
//        String APP_NAME = "Console";
//        RichTextLabel console_node;
        Array LOG;

//        godot_signal console_update;

    public:
        static void _register_methods();

        GDNShell();
        ~GDNShell();

        void spawn(Variant node);
        bool send_string(String string);
        bool send_input(int scancode);
        void kill();

        void _init(); // our initializer called by Godot

        void _process(float delta);
    };

}

#endif //GDNATIVE_LIBRARY_H
