# polypodium_core

[![CI](https://github.com/bruno1pb13/polypodium_core/actions/workflows/ci.yml/badge.svg)](https://github.com/bruno1pb13/polypodium_core/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Pacote Dart puro com as regras de sincronização compartilhadas entre o app [Polypodium](https://github.com/bruno1pb13/Polypodium) e o [Polypodium_server](https://github.com/bruno1pb13/Polypodium_server) — uma única fonte para que os dois lados não divirjam.

- **`incomingWins`** — comparador last-write-wins completo (o do servidor): `updatedAt` mais novo vence; empate desempata pelo maior `deviceId`.
- **`shouldApplyRemote`** — o mesmo critério no app, que não guarda `deviceId` por linha: em empate exato, a mudança remota vence.
- **`SyncChange`** — o registro de mudança trafegado em `/sync/changes` e `/sync/receive`.
- **`lwwVectors`** (`package:polypodium_core/lww_vectors.dart`) — casos de teste compartilhados; o servidor os executa contra o SQL do `ON CONFLICT` para garantir que ele continue idêntico ao comparador.

## Uso

```yaml
dependencies:
  polypodium_core:
    git:
      url: https://github.com/bruno1pb13/polypodium_core.git
      ref: v0.1.0
```

## Desenvolvimento

```bash
dart pub get
dart analyze
dart test
```

Mudanças de comportamento exigem uma nova tag e a atualização do `ref` no app e no servidor.

## Licença

[MIT](LICENSE)
