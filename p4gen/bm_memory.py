import os
from subprocess import call

from p4template import *

def benchmark_memory(args):
    program_name = 'output'
    if not os.path.exists(program_name):
       os.makedirs(program_name)

    fwd_tbl = 'forward_table'

    program = p4_define() + ethernet() + ipv4() + tcp()
    header_type_name = 'memtest_t'
    header_name = 'memtest'
    parser_state_name = 'parse_memtest'
    field_dec  = add_header_field('register_op', 4)
    field_dec += add_header_field('index', 12)
    field_dec += add_header_field('data', args.element_width)

    program += udp(select_case(0x9091, parser_state_name))
    program += add_header(header_type_name, field_dec)
    program += add_parser_without_select(header_type_name, header_name,
                    parser_state_name, 'ingress')

    metadata = 'mem_metadata'
    program += add_metadata_instance(header_type_name, metadata)

    field = '%s.data' % metadata
    index = '%s.index' % header_name
    commands = ''

    program += nop_action()

    read_set = ''
    write_set = ''
    for i in range(args.registers):
        register_name = 'register_%d' % i
        program   += add_register(register_name, args.element_width, args.nb_element)
        read_set  += register_read(register_name, field, index)
        write_set += register_write(register_name, field, index)

    program += register_actions(read_set, write_set)
    matches = '%s.register_op : exact;' % header_name
    actions = 'get_value; put_value; _nop;'
    table_name = 'register_table'
    program += add_table(table_name, matches, actions, 3)
    applies = apply_table(table_name)

    program += forward_table()
    program += control(fwd_tbl, applies)

    with open ('%s/main.p4' % program_name, 'w') as out:
        out.write(program)

    commands += cli_commands(fwd_tbl)
    with open ('%s/commands.txt' % program_name, 'w') as out:
        out.write(commands)

    call(['cp', 'template/run_switch.sh', program_name])