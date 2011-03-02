function dependents = getAllDependents( dj )
% DJ/getAllDependents(dj)  - returns the list of all descendents of dj
% in order of their dependencies. In the present MySQL implementation, this
% takes a long time (about 0.5 seconds per table).
%
% :: Dimitri Yatsenko :: Created 2011-01-21 :: Modified 2011-01-25 ::

queue = {class(dj)};  % start with the root node
nodes = {class(dj)};  % start with the root node
C = 0;  % connectivity matrix

while ~isempty(queue)
    current = queue{1};
    queue = queue(2:end);
    j = find(strcmp(current,nodes));

    % add children
    children = getChildTables(eval(current));
    for i=1:length(children)
        ix = find(strcmp(children{i},nodes));
        if ~isempty(ix)
            C(j,ix)=1;
        else
            if ismember(which(children{i}), {'','variable'})
                warning( 'Did not find the class definition for "%s". Skipping.', children{i} );
            else
                nodes(end+1) = children(i);
                C(length(nodes),length(nodes))=0;
                C(j,length(nodes))=1;
                if ~ismember( children{i}, queue )
                    queue(end+1)=children(i);
                end
            end
        end
    end
end

% assign level to every table
ik = 1:length(nodes);
levels = nan(size(ik));
level = 0;
while ~isempty(C)
    orphans = find(sum(C)==0);
    levels(ik(orphans)) = level;
    level = level+1;
    nonorphans = find(sum(C)>0);
    ik = ik(nonorphans);
    C = C(nonorphans,nonorphans);
end

% form the list of dependents
dependents = {};
for level=1:max(levels)
    dependents = [dependents, nodes(levels==level)];
end
