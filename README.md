# knot-bind-tsig
Convert TSIG key format from KNOT to BIND, and from BIND to KNOT

# Instalation
```
curl https://raw.githubusercontent.com/mateusz834/knot-bind-tsig/main/knot-bind-tsig.sh -o knot-bind-tsig.sh
chmod +x ./knot-bind-tsig.sh
```
# Usage
```
./knot-bind-tsig.sh knot.conf > bind.key
./knot-bind-tsig.sh bind.key > knot.conf
cat knot.conf | ./knot-bind-tsig.sh > bind.key
```

