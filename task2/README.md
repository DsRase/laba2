# Лаба 2: SD-WAN

Сначала выдаём скрипту права и прогоняем его: `chmod +x bootstrap.sh && ./bootstrap.sh`

Дальше поднимаем стенд: `docker compose up --build -d`

Заходим в `office_msk` и смотрим, какой интерфейс смотрит в оптику (у этого канала ip 10.10.0.10): `docker exec -it office_msk ip -br addr`

Когда нашли интерфейс - вырубаем его через netem (подставьте свой `<iface>`): `docker exec -it office_msk tc qdisc change dev <iface> root netem loss 100%`

Теперь снова заходим в контейнер и пингуем второй филиал по overlay: `docker exec -it office_msk ping 172.16.99.2`. Пинг не должен пропасть - агент `link_watchdog.py` увидит потери и сам переключит туннель на спутниковый канал, можно посмотреть в логах: `docker compose logs -f office_msk`

Чтобы вернуть оптику обратно: `docker exec -it office_msk tc qdisc change dev <iface> root netem delay 12ms 2ms`

## DoD

1. Готовим конфиги и поднимаем стенд:
   ```
   chmod +x bootstrap.sh && ./bootstrap.sh
   docker compose up --build -d
   ```
   Ожидаем: оба контейнера `office_msk` и `office_spb` в статусе `Up` (`docker compose ps`).

2. Базовая проверка overlay — пингуем второй филиал по адресу WireGuard:
   ```
   docker exec office_msk ping -c 4 172.16.99.2
   ```
   Ожидаем: `0% packet loss`, RTT около 20–30 мс. Туннель идёт через основной канал (fiber).

3. Пинг в обратную сторону, чтобы убедиться, что overlay симметричный:
   ```
   docker exec office_spb ping -c 4 172.16.99.1
   ```
   Ожидаем: тоже `0% packet loss`.

4. Находим интерфейс оптики (тот, у которого адрес из подсети `10.10.0.0/24`):
   ```
   docker exec -it office_msk ip -br addr
   ```
   Запоминаем имя интерфейса (обычно `eth1`).

5. В одном терминале запускаем длинный пинг, чтобы видеть переключение в реальном времени:
   ```
   docker exec office_msk ping 172.16.99.2
   ```

6. В другом терминале имитируем обрыв оптики - ставим 100% потерь:
   ```
   docker exec -it office_msk tc qdisc change dev <iface> root netem loss 100%
   ```
   Ожидаем: в окне с пингом несколько пакетов (3–6 штук) могут потеряться, после чего пинг **возобновляется**, но RTT скачком вырастает до 400–500 мс - это уже спутниковый канал. Связь не пропала.

7. Параллельно в третьем терминале смотрим логи watchdog'а:
   ```
   docker compose logs -f office_msk
   ```
   Ожидаем: строку вида `переключаемся на endpoint 10.20.0.20:51199` и далее `active=sat` в строках со статистикой.

8. Возвращаем оптику обратно:
   ```
   docker exec -it office_msk tc qdisc change dev <iface> root netem delay 12ms 2ms
   ```
   Через несколько циклов опроса (около 15–25 секунд) в логах появится обратное переключение `active=fiber`, RTT в пинге снова упадёт до ~25 мс.
