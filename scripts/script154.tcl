#Create a simulator object
set ns [new Simulator]

#Define the output files
set f0 [open out0NewReno_Reno_10_9BR.tr w]
set f1 [open out1NewReno_Reno_10_9BR.tr w]
set f2 [open out2NewReno_Reno_10_9BR.tr w]


#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green

#Open the NAM trace file
set nf [open outNewReno_Reno_10_9BR.nam w]
set nf2 [open out_mainNewReno_Reno_10_9BR.tr w]
$ns namtrace-all $nf
$ns trace-all $nf2



#Create 6 nodes
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

#Create links between the nodes

$ns duplex-link $n1 $n2 10Mb 10ms DropTail
$ns duplex-link $n5 $n2 10Mb 10ms DropTail
$ns duplex-link $n2 $n3 10Mb 10ms DropTail
$ns duplex-link $n3 $n4 10Mb 10ms DropTail
$ns duplex-link $n3 $n6 10Mb 10ms DropTail

#Set Queue Size of link (n2-n3) to 10
$ns queue-limit $n2 $n3 10

#Give node position (for NAM)
$ns duplex-link-op $n1 $n2 orient right-down
$ns duplex-link-op $n2 $n5 orient left-down
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n6 orient right-down

#Monitor the queue for link (n2-n3). (for NAM)
$ns duplex-link-op $n2 $n3 queuePos 0.5

#Setup a TCP connection for center of network
#set tcp [new Agent/TCP]
#$tcp set class_ 2
#$ns attach-agent $n2 $tcp
#set sink [new Agent/TCPSink]
#$ns attach-agent $n3 $sink
#$ns connect $tcp $sink
#$tcp set fid_ 1

#Setup a UDP connection for center of network
set udp [new Agent/UDP]
$ns attach-agent $n2 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_ 2

#Setup a TCP connection
set tcp1 [new Agent/TCP/NewReno]
$tcp1 set class_ 2
$ns attach-agent $n1 $tcp1
set sink0 [new Agent/TCPSink]
$ns attach-agent $n4 $sink0
$ns connect $tcp1 $sink0
$tcp1 set fid_ 2

#Setup a TCP connection
set tcp1 [new Agent/TCP/Reno]
$tcp2 set class_ 3
$ns attach-agent $n5 $tcp2
set sink1 [new Agent/TCPSink]
$ns attach-agent $n6 $sink1
$ns connect $tcp2 $sink1
$tcp2 set fid_ 3


#Setup a FTP over TCP connection
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP
$ftp1 set rate_ 10mb
$ftp1 set class_ 3

#Setup a FTP over TCP connection
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ftp2 set type_ FTP
$ftp2 set rate_ 10mb
$ftp2 set class_ 3

#Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 9mb
$cbr set random_ false

#Print CBR packet size and interval
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"

proc record {} {
global sink0 sink1 sink f0 f1 f2
set ns [Simulator instance]
set time 10.0
set bw0 [$sink0 set bytes_]
set bw1 [$sink1 set bytes_]
set bw2 [$sink set bytes_]
set now [$ns now]
puts $f0 "$now [expr $bw0/$time*8/1000000]"
puts $f1 "$now [expr $bw1/$time*8/1000000]"
puts $f2 "$now [expr $bw2/$time*8/1000000]"
$sink0 set bytes_ 0
$sink1 set bytes_ 0
$sink set bytes_ 0
$ns at [expr $now+$time] "record"
}

#Define a 'finish' procedure
proc finish {} {
global ns nf f0 f1 f2
close $f0
close $f1
close $f2
$ns flush-trace
#Close the NAM trace file
close $nf
#Execute NAM on the trace file
#exec xgraph out0.tr out1.tr out2.tr -geometry 800x400 &
#exec nam out.nam &
exit 0
}

#Schedule events for the CBR and FTP agents
$ns at 0.0 "$cbr start"
$ns at 0.0 "$ftp1 start"
$ns at 0.0 "$ftp2 start"
$ns at 10.0 "$ftp1 stop"
$ns at 10.0 "$ftp2 stop"
$ns at 10.0 "$cbr stop"


#Call the finish procedure after 5 seconds of simulation time
$ns at 15.0 "finish"



#Run the simulation

$ns run

