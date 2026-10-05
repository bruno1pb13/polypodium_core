# polypodium_core

[![CI](https://github.com/bruno1pb13/polypodium_core/actions/workflows/ci.yml/badge.svg)](https://github.com/bruno1pb13/polypodium_core/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Pacote Dart puro com as regras de sincronização compartilhadas entre o app [Polypodium](https://github.com/bruno1pb13/Polypodium) e o [Polypodium_server](https://github.com/bruno1pb13/Polypodium_server) — uma única fonte para que os dois lados não divirjam.

- **`incomingWins`** — o comparador last-write-wins, o mesmo no app e no servidor: `updatedAt` mais novo vence; em empate exato, vence o maior `deviceId`; reenviar a mesma mudança não altera nada. Um `deviceId` nulo (linha sem autor conhecido) é comparado como string vazia, perdendo qualquer empate contra um dispositivo conhecido.
- **`SyncChange`** — o registro de mudança trafegado em `/sync/changes` e `/sync/receive`.
- **`lwwVectors`** (`package:polypodium_core/lww_vectors.dart`) — casos de teste compartilhados; o servidor os executa contra o SQL do `ON CONFLICT` para garantir que ele continue idêntico ao comparador.

## Uso

```yaml
dependencies:
  polypodium_core:
    git:
      url: https://github.com/bruno1pb13/polypodium_core.git
      ref: v0.2.0
```

## Desenvolvimento

```bash
dart pub get
dart analyze
dart test
```

Mudanças de comportamento exigem uma nova tag e a atualização do `ref` no app e no servidor. O histórico está no [CHANGELOG](CHANGELOG.md).

## Licença

[MIT](LICENSE)
