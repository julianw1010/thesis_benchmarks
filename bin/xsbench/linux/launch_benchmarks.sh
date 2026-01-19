trap "echo 'Interrupted. Exiting...'; exit 1" SIGINT
./launch_xsbench.sh
./launch_xsbench_i.sh
