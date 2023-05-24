#ifndef GDNATIVE_LIBRARY_H
#define GDNATIVE_LIBRARY_H

#include <Godot.hpp>
#include <Sprite.hpp>

namespace godot {

    class GDN : public Sprite {
        GODOT_CLASS(GDN, Sprite)

    private:
        float time_passed;

    public:
        static void _register_methods();

        GDN();
        ~GDN();

        void _init(); // our initializer called by Godot

        void _process(float delta);
    };

}

#endif //GDNATIVE_LIBRARY_H
