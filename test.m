% Klayout
k = Klayout;
pgon = k.pya.Polygon.from_s("(1, 2; 2, 2; 0, 1)");
% Translation
pgon.move(1, 1);
% Rotation
% Calculate the rotation matrix
angle = 30;
% Create a transformation: translate from -x_ref, -y_ref rotate, translate
% back
pgon.move(-1, -2);
transformation = k.pya.CplxTrans(1, 30, py.bool(0), 0, 0);
pgon.transform(transformation);
pgon.move(1, 2);




% Polygon class
p = Polygon(Vertices=[1, 2; 3, 1; 4, 5]);
disp(p.Vertices)
p.plot(FigIndex=1, FaceColor="blue")
p.Vertices = [0, 2; 3, 2; 5, 8];
figure(1)
hold on
p.plot(FigIndex=1, FaceColor="red")
p.move([-1, 3]);
m = p.copy;
p.plot(FigIndex=1, FaceColor="magenta")
q = p.copy;
q.move([4, -2]);
q.plot(FigIndex=1, FaceColor="black")

% Union
p.move([5, 0]);
r = q+p;
r.plot(FigIndex=2)

% Difference
p = Polygon(Vertices=[1, 10; 4, 1; 4, 5]);
r = q-p;
r.plot(FigIndex=3)
r = m-p-q;
r.plot(FigIndex=3)

% Move
p = Polygon(Vertices=[1, 10; 4, 1; 4, 5]);
q = p.copy;
p.move([0, 2]);
t = p.intersect(q);
q.plot(FigIndex=4, FaceColor="red")
hold on
p.plot(FigIndex=4, FaceColor="blue")
t.plot(FigIndex=4, FaceColor="black", FaceAlpha = 1)

% XOR
t = m.xor(p);
m.plot(FigIndex=5, FaceColor="red")
hold on
p.plot(FigIndex=5, FaceColor="blue")
t.plot(FigIndex=5, FaceColor="black", FaceAlpha = 1)

% Rotate
y = p.copy;
p.rotate(25, [1, 2]);
y.plot(FigIndex=6, FaceColor="blue")
hold on
p.plot(FigIndex=6, FaceColor="red")

% Scale
y = p.copy;
p.scale(4);
y.plot(FigIndex=7, FaceColor="blue")
hold on
p.plot(FigIndex=7, FaceColor="red")

% Flip horizontally
p.plot(FigIndex=8)
hold on
p.flip_horizontally;
p.plot(FigIndex=8)

% Flip vertically
p.plot(FigIndex=9)
hold on
p.flip_vertically;
p.plot(FigIndex=9)
