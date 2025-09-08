lib: {
  listToNestedAttrs = f: list:
    lib.foldl' (acc: x:
      acc // lib.setAttrByPath x.segs (f x)
    ) {} list;
}
