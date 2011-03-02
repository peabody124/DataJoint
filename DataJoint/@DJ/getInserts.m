function str = getInserts( dj )
% getInserts( dj ) - returns insert statments for the relation dj.
% dj must not have any blob fields
%
% :: Dimitri Yatsenko :: Created 2011-02-23 :: Modified 2011-02-23 ::

assert( ~any([dj.fields.isBlob]), 'no blobs allowed for this operation' );

str = '';
head = sprintf('inserti(%s,struct(',class(dj));
s=fetch( dj,'*');
f=fieldnames(s);
numeric = zeros(size(f));
for i=1:length(f)
    ix=find(strcmp(f{i},{dj.fields.name}));
    numeric(i) = dj.fields(ix).isNumeric;
end

for s = s'
    list = '';
    for i=1:length(f)
        v = s.(f{i});
        if numeric(i)
            if ~isnan(v)
                vs = sprintf('%1.16g',v);
                if ~isempty(regexp(vs,'000000|999999'))
                    vs = sprintf('%1.8g',v);
                end
                list = sprintf('%s,''%s'',%s',list,f{i},vs);
            end
        else
            list = sprintf('%s,''%s'',''%s''',list,f{i},v);
        end
    end
    str = sprintf('%s%s%s));\n',str,head,list(2:end));
end




