# Messaging Contracts

These JSON files document the wire shape of every event published over RabbitMQ.

## How messaging works

```
Identity service
  AppUser.Ban() / UpdateProfile() / Create()
       │
       ▼ domain event written to OutboxMessages table
  OutboxPublisher (BackgroundService, polls every 5s)
       │
       ▼ bus.Publish(event) via MassTransit
  RabbitMQ exchange  (named by C# type: "UserBannedEvent" etc.)
       │
       ├─▶ Finance queue  ──▶ UserBannedConsumer
       └─▶ Forum queue  ──▶ UserBannedConsumer
```

MassTransit routes by **C# type name**. Each consuming service defines an identical record type in the same namespace (`Infrastructure.Messaging.Events`) with the same property shape. The exchange name is derived from that type name — so all three services must agree on the shape.

**The JSON files here are the single source of truth** for that shape. If you change a field in Identity's event record, you must update the matching records in Finance and Forum, and update the JSON here.

## Events

| File | Published by | Consumed by |
|---|---|---|
| [identity.user_registered.json](events/identity.user_registered.json) | Identity | Finance, Forum |
| [identity.user_profile_updated.json](events/identity.user_profile_updated.json) | Identity | Finance, Forum |
| [identity.user_banned.json](events/identity.user_banned.json) | Identity | Finance, Forum |

## Adding a new event

1. Add the domain event to the publishing service's `Domain/Events/`
2. Add a wire record to the publisher's `Infrastructure/Messaging/Events/`
3. Register it in `OutboxPublisher.EventTypeMap`
4. Add matching record(s) in each consuming service's `Infrastructure/Messaging/Events/`
5. Implement `IConsumer<TEvent>` in each consuming service and register it via `AddConsumer<>()` in `InfrastructureServiceExtensions`
6. Add the JSON contract file here
