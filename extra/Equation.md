
# System

div(I) = 0
-grad(e) = rho I


# Apply div to (2)

-div(grad(e)) = div(rho I) = grad(rho) . I + rho * div(I) = grad(rho) . I

div(I) = 0
lapl(e) + grad(rho) . I = 0

# Use conductivity instead of resistence

div(I) = 0
grad(e) * con = I

div(grad(e) * con) = div(I) = 0

div(grad(e)) * con + grad(e) . grad(con) = 0
(div(grad(e)) * con * v) + (grad(e) . grad(con) * v) = 0

- grad(e) . grad(con * v)
- grad(e) . [ con * grad(v) + grad(con) * v ]
