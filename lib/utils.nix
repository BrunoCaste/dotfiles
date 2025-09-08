lib: {
  listToNestedAttrs = f: list:
    lib.foldl' (acc: x:
      acc // lib.setAttrsByPath x.segs (f x)
    ) {} list;
}
