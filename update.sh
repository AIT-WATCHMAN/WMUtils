
if ! [ -f "./.git/hooks/post-checkout" ]
then
  cp .additions/post-checkout ./.git/hooks/post-checkout
fi
if ! [ -f "./.git/hooks/post-merge" ]
then
  cp .additions/post-merge ./.git/hooks/post-merge
fi

git submodule update --recursive --init
