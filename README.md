# ru-geo-block-mini

Мини-сборка geo-файлов (`geoip.dat` / `geosite.dat`) **только с заблокированными в РФ ресурсами** и нужными сервисами — для роутеров с малым объёмом флеша и RAM (OpenWrt + PassWall2/Xray).

Обычные файлы из `russia-v2ray-rules-dat` весят ~41 МБ и не влезают в 37 МБ overlay. Эта сборка даёт **~1.5-3 МБ** и содержит только те категории, которые вы включили.

## Готовые файлы (всегда последняя версия)

- **geosite.dat** — https://github.com/kalchevsky/ru-geo-block-mini-/releases/latest/download/geosite.dat
- **geoip.dat** — https://github.com/kalchevsky/ru-geo-block-mini-/releases/latest/download/geoip.dat

Ссылки стабильные: они всегда указывают на последний релиз, менять ничего не нужно.

## Как настроить категории

Отредактируйте два файла — и запушьте в `main`:

| Файл | Что задаёт |
|---|---|
| `config/geosite.list` | категории доменов → `geosite.dat` |
| `config/geoip.list` | категории подсетей → `geoip.dat` |

Одна категория на строку, `#` — комментарий. Полный список доступных категорий:
<https://github.com/runetfreedom/russia-blocked-geosite#доступные-категории>

**По умолчанию включено:** `ru-blocked`, `google`, `youtube`, `discord`, `telegram`, `meta`, `twitter`, `openai`.

> ⚠️ Каждая категория увеличивает файл и потребление RAM на роутере. `ru-blocked-all` (~700k доменов) — самый тяжёлый, на слабых роутерах его включать не стоит.

## Как это работает

```
GitHub Actions (каждые 6 часов + по кнопке)
  ├─ качает полные geosite.dat / geoip.dat от runetfreedom
  ├─ geoview: оставляет только категории из config/*.list
  ├─ проверяет, что результат — валидный protobuf
  └─ создаёт Release с geosite.dat, geoip.dat и .sha256sum
```

Скрипт сборки: [`scripts/build.sh`](scripts/build.sh). Workflow: [`.github/workflows/build.yml`](.github/workflows/build.yml).

## Запустить вручную

Actions → **Build mini geo** → **Run workflow**.

Локально (нужен `bash`, `curl`, `sha256sum`):

```bash
./scripts/test-local.sh
```

## Использование на OpenWrt (PassWall2)

```sh
# 1) Скачать в /tmp и проверить
cd /tmp
wget -O geosite.dat https://github.com/kalchevsky/ru-geo-block-mini-/releases/latest/download/geosite.dat
wget -O geoip.dat   https://github.com/kalchevsky/ru-geo-block-mini-/releases/latest/download/geoip.dat

# 2) Заменить большие файлы (симлинки /usr/share/xray/*.dat указывают сюда)
mv /tmp/geosite.dat /usr/share/v2ray/geosite.dat
mv /tmp/geoip.dat   /usr/share/v2ray/geoip.dat

# 3) Перезапустить PassWall2
/etc/init.d/passwall2 restart
```

Затем в PassWall2 в правиле **Russia_Block** должно оставаться `geosite:ru-blocked`.

## Обновление на роутере

Раз в сутки можно обновлять автоматически:

```sh
# /usr/bin/geo-update.sh
#!/bin/sh
BASE=https://github.com/kalchevsky/ru-geo-block-mini-/releases/latest/download
cd /tmp || exit 1
wget -q -O geosite.new $BASE/geosite.dat || exit 1
wget -q -O geoip.new   $BASE/geoip.dat   || exit 1
# не подменяем битые файлы
[ -s geosite.new ] && [ -s geoip.new ] || exit 1
mv geosite.new /usr/share/v2ray/geosite.dat
mv geoip.new   /usr/share/v2ray/geoip.dat
/etc/init.d/passwall2 restart
```

```sh
# cron: ежедневно в 04:30
echo '30 4 * * * /usr/bin/geo-update.sh' >> /etc/crontabs/root
/etc/init.d/cron restart
```

## Источники данных

- [runetfreedom/russia-blocked-geosite](https://github.com/runetfreedom/russia-blocked-geosite) — домены (antifilter.download, community.antifilter.download, re:filter)
- [runetfreedom/russia-blocked-geoip](https://github.com/runetfreedom/russia-blocked-geoip) — IP-подсети
- [urlesistiana/geoview](https://github.com/urlesistiana/geoview) — инструмент нарезки

## Лицензия

MIT — см. [LICENSE](LICENSE). Данные принадлежат их авторам (GPL-3.0 у runetfreedom).
