#Create a simulator object
set ns [new Simulator]

#Define the output files
set f0 [open out0_R_R_20_25BR.tr w]
set f1 [open out1_R_R_20_25BR.tr w]
set f2 [open out2_R_R_20_25BR.tr w]




#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green 

#Open the NAM trace file
set nf [open out_R_R_20_25BR.nam w]
set nf2 [open out_main_R_R_20_25BR.tr w]
$ns namtrace-all $nf
$ns trace-all $nf2


#Create nodes
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

#Create links between the nodes
#10mb link btwn n_i and n_j
$ns duplex-link $n1 $n2 10Mb 10ms DropTail
$ns duplex-link $n5 $n2 10Mb 10ms DropTail
$ns duplex-link $n2 $n3 10Mb 10ms DropTail
$ns duplex-link $n3 $n4 10Mb 10ms DropTail
$ns duplex-link $n3 $n6 10Mb 10ms DropTail

#Set Queue Size of link (n2-n3) to 10
$ns queue-limit $n2 $n3 20


#Give node position (for NAM)
$ns duplex-link-op $n1 $n2 orient right-down
$ns duplex-link-op $n2 $n5 orient left-down 
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n6 orient right-down

#Monitor the queue for link (n2-n3). (for NAM)
$ns duplex-link-op $n2 $n3 queuePos 0.5



#Setup a TCP connection between nodes 2 and 3
set tcp [new Agent/TCP]
$tcp set class_ 2
#n2 is the source
$ns attach-agent $n2 $tcp
#node 3 is sink
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink
$tcp set fid_ 1




#Setup a TCP connection between nodes 1 and 4
set tcp1 [new Agent/TCP/Reno]
$tcp1 set class_ 2
#source at node 1
$ns attach-agent $n1 $tcp1
#sink at node 4
set sink0 [new Agent/TCPSink]
$ns attach-agent $n4 $sink0
$ns connect $tcp1 $sink0
$tcp1 set fid_ 2

#Setup a TCP connection between nodes 5 and 6
set tcp2 [new Agent/TCP/Reno]
$tcp2 set class_ 3
#node 5 is source
$ns attach-agent $n5 $tcp2
set sink1 [new Agent/TCPSink]
#node 6 is sink
$ns attach-agent $n6 $sink1
$ns connect $tcp2 $sink1
$tcp2 set fid_ 3


#Setup a FTP over TCP connection (node 1 to 4)
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP
$ftp1 set class_ 3

#Setup a FTP over TCP connection (node 5 to 6)
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ftp2 set type_ FTP
$ftp2 set class_ 3


#set cbr1 [new Application/Traffic/CBR]
#$cbr1 attach-agent $tcp1
#$cbr1 set type_ CBR
#$cbr1 set packet_size_ 1000
#$cbr1 set rate_ 10mb
#$cbr1 set random_ false


#Setup a CBR over TCP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $tcp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 25mb
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
$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp1 start"
$ns at 1.0 "$ftp2 start"
$ns at 8.0 "$ftp1 stop"
$ns at 8.0 "$ftp2 stop"
$ns at 9.0 "$cbr stop"

#Detach tcp and sink agents (not really necessary)
#$ns at 4.5 "$ns detach-agent $n0 $tcp ; $ns detach-agent $n3 $sink"

#Call the finish procedure after 5 seconds of simulation time
$ns at 10.1 "finish"



#Run the simulation
$ns at 10.0 "record"
$ns run

