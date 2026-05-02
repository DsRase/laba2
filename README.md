# Лаба 2: SD-WAN

Сначала выдаём скрипту права и прогоняем его: `chmod +x bootstrap.sh && ./bootstrap.sh`

Дальше поднимаем стенд: `docker compose up --build -d`

Заходим в `office_msk` и смотрим, какой интерфейс смотрит в оптику (у этого канала ip 10.10.0.10): `docker exec -it office_msk ip -br addr`

Когда нашли интерфейс - вырубаем его через netem (подставьте свой `<iface>`): `docker exec -it office_msk tc qdisc change dev <iface> root netem loss 100%`

Теперь снова заходим в контейнер и пингуем второй филиал по overlay: `docker exec -it office_msk ping 172.16.99.2`. Пинг не должен пропасть - агент `link_watchdog.py` увидит потери и сам переключит туннель на спутниковый канал, можно посмотреть в логах: `docker compose logs -f office_msk`

Чтобы вернуть оптику обратно: `docker exec -it office_msk tc qdisc change dev <iface> root netem delay 12ms 2ms`
