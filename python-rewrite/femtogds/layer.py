"""Layer settings shared by all its geometrical features."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Layer:
    """Choose the two destinations once for every object on this layer."""

    name: str
    comsol: bool = True
    gds: bool = True
    gds_layer: int = 1
    gds_datatype: int = 0

    def __post_init__(self):
        if not isinstance(self.name, str) or not self.name.strip():
            raise ValueError("A layer needs a nonempty name.")
        if not isinstance(self.comsol, bool) or not isinstance(self.gds, bool):
            raise ValueError("The comsol and gds layer flags must be booleans.")
        for name in ("gds_layer", "gds_datatype"):
            value = getattr(self, name)
            if type(value) is not int or not 0 <= value <= 65535:
                raise ValueError(f"{name} must be an integer between 0 and 65535.")
