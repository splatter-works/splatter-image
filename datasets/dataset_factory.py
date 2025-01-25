from .co3d import CO3DDataset


def get_dataset(cfg, name):
    if cfg.data.category == "hydrants" or cfg.data.category == "teddybears":
        return CO3DDataset(cfg, name)
