./launch_xsbench_r.sh
trap "echo 'Interrupted. Exiting...'; exit 1" SIGINT
./launch_xsbench_r_i.sh
