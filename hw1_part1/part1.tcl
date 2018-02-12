#Create a simulator object
set ns [new Simulator]

#Define the output files
set f0 [open out0.tr w]
set f1 [open out1.tr w]
set f2 [open out2.tr w]


#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green 

#Open the NAM trace file
set nf [open out.nam w]
set nf2 [open out_main.tr w]
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
$ns queue-limit $n2 $n3 10

#Give node position (for NAM)
$ns duplex-link-op $n1 $n2 orient right-down
$ns duplex-link-op $n2 $n5 orient left-down 
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n6 orient right-down

#Monitor the queue for link (n2-n3). (for NAM)
$ns duplex-link-op $n2 $n3 queuePos 0.5

#set up tcp connection between nodes 1 and 4
set tcp1 [$ns create-connection TCP/Reno $n1 TCPSink $n4 0]
#$tcp1 set window_ 15
#set up tcp connection between nodes 5 and 6
set tcp2 [$ns create-connection TCP/Reno $n5 TCPSink $n6 1]
#set up tc connection between nodes 2 and 3
set tcp3 [$ns create-connection TCP/Reno $n2 TCPSink $n3 2]
#$tcp2 set window_ 15
#set up ftp between 1-4 and 5-6
set ftp1 [$tcp1 attach-source FTP]
set ftp2 [$tcp2 attach-source FTP]

#Setup a CBR over TCP connection btwn nodes 2 and 3
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $tcp3
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 10mb
$cbr set random_ false



#Print CBR packet size and interval
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"


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

$ns run

