kill_process_by_port() {
  port=$1
  pid=$(lsof -t -i:$port)

  if [ -n "$pid" ]; then
    echo "Killing process on port $port with PID $pid"
    kill $pid
  else
    echo "No process found on port $port"
  fi
}

kill_process_by_port 7077
kill_process_by_port 8080
kill_process_by_port 8081
kill_process_by_port 4040
