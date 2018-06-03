splat(*splat1)
splat(1, 2, 3, *splat1)
splat(1, 2, 3, *splat1, *splat2)

double_splat(**splat_splat1)
double_splat(1, 2, 3, **splat_splat1)
double_splat(1, 2, 3, **splat_splat1, **splat_splat2)

all_with_args(1, 2, 3, *splat, **splat_splat)
all_with_args_and_block(1, 2, 3, *splat1, **splat_splat1, &block)
all_with_args_and_block(1, 2, 3, *splat1, *splat2, *splat3, **splat_splat1, **splat_splat2, **splat_splat3, &block)

def foo(arg1, *splat, **splat_splat)

end
