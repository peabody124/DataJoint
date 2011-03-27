function erd( dj, varargin )
% erd(dj) - plot the Entity Relationship Diagram of all tables linked to dj.
% erd(dj,dir1,...,dirn); -- only include tables whose classes are defined in
% directories dir1,...,dirn.
%
% :: Dimitri Yatsenko :: Created 2010-12-29 :: Modified 2010-03-26 ::

includeReferences = false; 
[nodes,C,yi] = getAllTables(dj,false);
assert( iscellstr(varargin), 'directories must be provied as character strings' );

% restrict to those classes that are in given directories
if ~isempty(varargin)
    ix = [];
    for i=1:length(varargin)
        % restrict to tables  whose classes are defined in 'classDirectory'
        lst = dir(fullfile(varargin{i},'@*'));
        lst = cellfun( @(x) x(2:end), {lst.name}, 'UniformOutput', false );
        ix = union(ix,find(ismember(nodes,lst)));
    end
    assert( ~isempty(ix), 'No table classes found matching directories' );
    nodes = nodes(ix);
    C = C(ix,ix);
    yi = yi(ix);
end
yi = -yi;
xi = zeros(size(yi));

% optimize graph appearance by minimizing disctances.^2 to connected nodes
% while maximizing distances to nodes on the same level.
fprintf('optimizing layout...');
j1 = cell(1,length(xi));
j2 = cell(1,length(xi));
dx = 0;
for i=1:length(xi)
    j1{i} = setdiff(find(yi==yi(i)),i);
    j2{i} = [find(C(i,:)) find(C(:,i)')];
end
niter=5e4;
T0=5; % initial temperature
cr=6/niter; % cooling rate
L = inf(size(xi));
for iter=1:niter
    i = ceil(rand*length(xi));  % pick a random node

    % Compute the cost function Lnew of the increasing xi(i) by dx
    dx = 5*randn*exp(-cr*iter/2);  % steps don't cools as fast as the annealing schedule
    xx=xi(i)+dx;
    Lnew = sum(abs(xx-xi(j2{i}))); % punish for remoteness to connected nodes
    if ~isempty(j1{i})
        Lnew= Lnew+sum(1./(0.01+(xx-xi(j1{i})).^2));  % punish for propximity to same-level nodes
    end

    if L(i) > Lnew + T0*randn*exp(-cr*iter) % simulated annealing
        xi(i)=xi(i)+dx;
        L(i) = Lnew;
    end
end
yi = yi+cos(xi*pi+yi*pi)*0.2;  % stagger y positions at each level


% plot nodes
plot(xi,yi,'o','MarkerSize',10);
hold on;
c = hsv(16);
% plot edges
for i=1:size(C,1)
    ci = round((yi(i)-min(yi))/(max(yi)-min(yi))*15)+1;
    cc = c(ci,:)*0.3+0.4;
    for j=1:size(C,2)
        if C(i,j)
            connect( xi([i j]), yi([i j]), '-', cc);
            hold on;
        end
    end
end
title('All dependencies are directed downward.');

% annotate nodes
for i=1:length(nodes)
    obj=eval(nodes{i});
    switch obj.tableType
        case 'm'
            c = [0 0.6 0];
        case 'l'
            c = [0.4 0.5 0.4];
        case 'i'
            c = [0 0 1];
        case 'c'
            c = [0.5 0.0 0];
    end
    if ismember(obj.tableType,'lm') || ~isempty(obj.populateRelation)
        w = 'bold';
    else
        w = 'light';
    end

    h = text(xi(i),yi(i),[nodes{i} '   '],'HorizontalAlignment','right', 'FontWeight', w, 'Color', c );
    hold on;
end

xlim( [min(xi)-0.5 max(xi)+0.5] );
ylim( [min(yi)-0.5 max(yi)+0.5] );
hold off;
axis off;
disp('done');
end



function connect( x, y, lineStyle, color )
assert(length(x)==2 && length(y)==2 );
plot( x, y, 'k.' );
t = 0:0.05:1;
x = x(1) + (x(2)-x(1)).*(1-cos(t*pi))/2;
y = y(1) + (y(2)-y(1))*t;
plot( x, y, lineStyle, 'Color', color );
end