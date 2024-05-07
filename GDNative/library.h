#ifndef GDNATIVE_LIBRARY_H
#define GDNATIVE_LIBRARY_H

#include <Godot.hpp>
#include <Node.hpp>
#include <File.hpp>


namespace godot {

    class GDNShell : public Node {
        GODOT_CLASS(GDNShell, Node)

    private:
        float time_passed{};
        Array LOG;

    public:
        static void _register_methods();

        GDNShell();
        ~GDNShell();

        int spawn(String path, bool hidden = false);
        bool send_string(String string);
//        int get_process_status();
//        bool is_waiting_for_input();
        void kill();

        int get_lines_count();
        String get_text(int _START_LINE, int _END_LINE);
        String get_all_text();
        void clear();

        Array disassemble(PoolByteArray bytes, int bit_format, unsigned int address);
        Dictionary analyze(PoolByteArray bytes, int bit_format, unsigned long long section_rva, unsigned long long entry_rva, unsigned long long image_base);

        void _init(); // our initializer called by Godot

        void _process(float delta);
    };

}

bool process_setup();

#endif //GDNATIVE_LIBRARY_H
