{ inputs }: final: prev: {
  helloCircus = prev.hello.overrideAttrs (_: { pname = "hello-circus"; });
}
