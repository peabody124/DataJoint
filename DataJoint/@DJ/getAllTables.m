function [nodes,C,levels] = getAllTables( dj, includeRefs )
% list = getAllTables( dj ) gets the list of all tables linked to dj
% in order of their dependencies.
%
% :: Dimitri Yatsenko :: Created 2011-02-10 :: Modified 2011-02-28 ::

includeRefs = nargin==1 || includeRefs;  % true by default

fprintf('Retrieving related tables...');
if ~includeRefs
    sql = [...
        'SELECT DISTINCT table_name, referenced_table_name ' ...
        'FROM information_schema.key_column_usage ' ...
        'WHERE constraint_name not like "ref%%" and referenced_table_schema="%s"'];
else
    sql = [...
        'SELECT DISTINCT table_name, referenced_table_name ' ...
        'FROM information_schema.key_column_usage ' ...
        'WHERE referenced_table_schema="%s"'];
end

sql = sprintf( sql, dj.conn.schema );
ret = query( dj, sql );
refSrc = regexprep(ret.table_name,'(^|\W|_)+([a-zA-Z]?)','${upper($2)}');
refDst = regexprep(ret.referenced_table_name,'(^|\W|_)+([a-zA-Z]?)','${upper($2)}');

C = 0;  % connectivity matrix
queue = {class(dj)};
nodes = {class(dj)};

while ~isempty(queue)
    current = queue{1};
    queue = queue(2:end);
    j = find(strcmp(current,nodes));

    % add parents
    obj = eval(current);
    parents = refDst(find(strcmp(refSrc,current)));
    for i=1:length(parents)
        if isempty(which(parents{i}))
            warning('Class %s not found',parents{i});
        else
            ix = find(strcmp(parents{i},nodes));
            if ~isempty(ix)
                C(ix,j)=1;
            else
                nodes(end+1) = parents(i);
                C(length(nodes),length(nodes))=0;
                C(length(nodes),j)=1;
                if ~ismember( parents{i}, queue )
                    queue(end+1)=parents(i);
                end
            end
        end
    end

    % add children
    children = refSrc(find(strcmp(refDst,current)));
    for i=1:length(children)
        if isempty(which(children{i}))
            warning('Class %s not found',children{i});
        else

            ix = find(strcmp(children{i},nodes));
            if ~isempty(ix)
                C(j,ix)=1;
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

% determine nodes' hierarchical levels
K = C;
ik = 1:length(nodes);
levels = nan(size(ik));
level = 0;
while ~isempty(K)
    orphans = find(sum(K)==0);
    levels(ik(orphans)) = level;
    level = level + 1;
    nonorphans = find(sum(K)>0);
    ik = ik(nonorphans);
    K = K(nonorphans,nonorphans);
end


% sort nodes by hierarchical level
[levels,ix] = sort(levels);
nodes = nodes(ix);
C = C(ix,ix);

disp('done');