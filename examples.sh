
# Find all destination TCP ports (1..1024) in all records (-1) at 3 september 2015
# Найти все входящие порты TCP (в диапазоне 1..1024) во всех записях 3 сентября 2015
nfdump -R gw1/2015/09/03 "proto tcp and dst net 91.244.183.0/24 and dst port < 1024" | ./investigate_ports.tcl 91.244.183. -1 >dst_port_popularity.txt

# Find all source TCP ports (1..1024) in all records (-1) at 3 september 2015
# Найти все исходящие порты TCP (в диапазоне 1..1024) во всех записях 3 сентября 2015
nfdump -R gw1/2015/09/03 "proto tcp and src net 91.244.183.0/24 and src port < 1024" | ./investigate_ports.tcl 91.244.183. -1 >src_port_popularity.txt

# Содержимое файлов имеет формат:
# ###1### targetmask=91.244.183.     <-- множество обследуемых IP-адресов
# ###2### maxreccount=-1             <-- обозначение количества записей - бесконечность
# SPort BytePassed                   <-- заголовок для исходящих портов
#  443:   34345345                   <-- номер порта и количество байтов переданных через него 
#   80:      44738
#   22:        423
# DPort BytePassed                   <-- заголовок для входящих портов
