models.map { |model| model.uuid }
models.map(&:uuid)
models.map &:uuid

[1, 2, 3].inject(&:+)
[1, 2, 3].inject &:+
