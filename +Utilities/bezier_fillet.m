function y = bezier_fillet(p0, p1, p3)
    % Calculate midpoints
    mid01 = [(p0(1) + p1(1)) / 2, (p0(2) + p1(2)) / 2];
    mid13 = [(p1(1) + p3(1)) / 2, (p1(2) + p3(2)) / 2];
    mid23 = [(mid01(1) + mid13(1)) / 2, (mid01(2) + mid13(2)) / 2];

    % Calculate control points for the Bezier curve
    control1 = [2 * mid01(1) - p1(1), 2 * mid01(2) - p1(2)];
    control2 = [2 * mid23(1) - 0.5 * (mid01(1) + mid13(1)), 2 * mid23(2) - 0.5 * (mid01(2) + mid13(2))];
    control3 = [2 * mid13(1) - p1(1), 2 * mid13(2) - p1(2)];

    % Calculate points of the Bezier curve
    t_values = (0:0.01:1);
    y = zeros(length(t_values), 2);

    for i = 1:length(t_values)
        t = t_values(i);
        y(i, 1) = (1 - t)^3 * p1(1) + 3 * (1 - t)^2 * t * control1(1) + 3 * (1 - t) * t^2 * control2(1) + t^3 * control3(1);
        y(i, 2) = (1 - t)^3 * p1(2) + 3 * (1 - t)^2 * t * control1(2) + 3 * (1 - t) * t^2 * control2(2) + t^3 * control3(2);
    end
end