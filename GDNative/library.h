#ifndef GDNATIVE_LIBRARY_H
#define GDNATIVE_LIBRARY_H

#include <Godot.hpp>
#include <Node.hpp>

namespace godot {

    class GDNShell : public Node {
        GODOT_CLASS(GDNShell, Node)

    private:
        float time_passed;
        Array LOG;

    public:
        static void _register_methods();

        GDNShell();
        ~GDNShell();

        void spawn(Variant node);
        bool send_string(String string);
        void kill();

        void _init(); // our initializer called by Godot

        void _process(float delta);
    };

}

bool process_setup();

#endif //GDNATIVE_LIBRARY_H
