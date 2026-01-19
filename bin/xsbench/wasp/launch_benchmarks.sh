./launch_xsbench.sh
trap "echo 'Interrupted. Exiting...'; exit 1" SIGINT
./launch_xsbench_i.sh
