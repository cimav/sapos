for p in `ps aux | grep unicorn | cut -d " " -f 5`
do
  echo "Mata $p"
  kill -9 $p
done
rake assets:clean
rake assets:precompile
