{ lib, ... }:
with lib; {
  listToNestedAttrs = f: list:
    foldl'
      (
        acc: x:
          acc // setAttrByPath (splitString "." x.name) (f x)
      )
      { }
      list;
}
