# Changelog

## 0.3.0

- Nova biblioteca `package:polypodium_core/weather.dart`, vinda do servidor para o app também poder calcular a rega pelo clima no workspace local: modelos e parser do Open-Meteo (`WeatherForecast`, `DailyWeather`, `parseOpenMeteo`, `openMeteoQuery`, agora com `utcOffset`), `distanceKm`, `isValidCoordinate`, `adviseWatering` com `WateringRules`, e a montagem dos dias (`wateringDays`, `likelyRain`, `meanEt0`, `wateringLocalDate`, `latestTimestamp`).

## 0.2.0

- `incomingWins` passa a ser o único comparador last-write-wins, usado pelo app e pelo servidor: o app agora guarda o `deviceId` de quem escreveu cada linha e desempata como o servidor.
- `incomingWins` aceita `deviceId` nulo (comparado como string vazia, perdendo qualquer empate contra um dispositivo conhecido) e `currentUpdatedAt` nulo (sem linha guardada: a mudança é aplicada).
- **Quebra:** `shouldApplyRemote` foi removido (o app era o único usuário), assim como o campo `LwwVector.shouldApplyRemote`; os `deviceId` de `LwwVector` agora são anuláveis.
- Novos vetores compartilhados para `deviceId` nulo.

## 0.1.0

- Versão inicial: `incomingWins`, `shouldApplyRemote`, `SyncChange` e os vetores compartilhados `lwwVectors`.
