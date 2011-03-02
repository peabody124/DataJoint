function R=pro(R,varargin)
% R=pro(R,attr1,...,attrn) - apply relational projection to relation R.
%
% Read DataJoint.pdf for a review of the relational data model and the uses
% of relational operators in DataJoint.
%
% INPUTS:
%    'attr1',...,'attrn' is a comma-separated string of relation attributes
% onto which to project the relation R.
%
% Primary key attributes are included implicitly and cannot be excluded.
%
% To rename an attribute, list it in the form 'old_name->new_name'.
%
% Computed attributes are always aliased:
% 'datediff(exp_date,now())->days_ago'
%
% When attr1 is '*', all attributes are included. Attributes can then be
% excluded by prefixing them with a tilde '~'.
%
% The order of attributes in the attribute list does not affect the
% ordering of attributes in the resulting relation.
%
% Example 1. Construct relation r2 containing only the primary keys of r1:
%    >> r2 = pro(r1);
%
% Example 2. Construct relation r3 which contains values for 'operator'
%    and 'anesthesia' for every tuple in r1:
%    >> r3=pro(r1,'operator','anesthesia');
%
% Example 3. Rename attribute 'anesthesia' to 'anesth' in relation r1:
%    >> r1 = pro( r1, '*','anesthesia->anesth');
%
% Example 4. Exclude attribute 'anesthesia' from relation r1.
%    >> r1 = pro( r1, '*', '~anesthesia');
%
% Example 5. Add field mouse_age in days to relation r1 that has the field mouse_dob:
%    >> r1 = pro( r1, '*', 'datediff(now(),mouse_dob)->mouse_age' );
%
% :: Dimitri Yatsenko :: Created 2010-10-30 :: Modified 2011-02-28 ::

assert( iscellstr( varargin ), 'Projection attributes must be specified as strings' );
if isempty(varargin)
    R.selfExpression = sprintf('pro(%s)',R.selfExpression);
else
    str = sprintf(',''%s''',varargin{:});
    R.selfExpression = sprintf('pro(%s,%s)',R.selfExpression,str(2:end));
end

[include,aliases,computedAttrs] = parseAttrList( R, varargin );

if ~all(include) || ~all(cellfun(@isempty,aliases)) || ~isempty(computedAttrs)
    R.fields = R.fields(include);
    aliases = aliases(include);
    R.primaryKey={R.fields([R.fields.isKey]).name};

    % add selected attributes
    fieldList = '';
    c = '';
    for iField=1:length(R.fields)
        fieldList=sprintf('%s%s`%s`',fieldList,c,R.fields(iField).name);
        if ~isempty(aliases{iField})
            R.fields(iField).name=aliases{iField};
            fieldList=sprintf('%s as `%s`',fieldList,aliases{iField});
        end
        c = ',';
    end

    % add computed attributes
    for iComp = 1:size(computedAttrs,1)
        R.fields(end+1) ...
            = struct('name',computedAttrs{iComp,2},'type','<sql_computed>','isKey',false,'isNumeric',false,'isString',false,'isBlob',false,'isNullable',false,'comment','SQL computation','default',[]);
        fieldList=sprintf('%s%s %s as `%s`',fieldList,c,computedAttrs{iComp,1},computedAttrs{iComp,2});
        c=',';
    end

    % update query
    if strcmp(R.sqlPro,'*')
        R.sqlPro = fieldList;
    else
        R.sqlSrc = sprintf('(SELECT %s FROM %s%s) as r',fieldList,R.sqlSrc,R.sqlRes);
        R.sqlPro = '*';
        R.sqlRes = '';
    end

end


function [include,aliases,computedAttrs] = parseAttrList( R, attrList )
% parse and validate the list of relation attributes in attrList.
% OUTPUT:
%    include: a logical array marking which fields of R must be included
%    aliases: a string array containing aliases for each of R's fields or '' if not aliased
%    computedAttrs: pairs of SQL expressions and their aliases.

include = [R.fields.isKey];  % implicitly include the primary key
aliases = repmat({''},size(R.fields));  % one per each R.fields
computedAttrs = {};

for iAttr=1:length(attrList)
    if strcmp('*',attrList{iAttr})
        include = include | true;   % include all attributes
    elseif strncmp(attrList{iAttr},'~',1)
        % exclude attributes prefixed by ~
        exAttr=strtrim(attrList{iAttr}(2:end));
        ix = find(strcmp(exAttr,{R.fields.name}));
        assert(~R.fields(ix).isKey,'DJ: Cannot exclude primary key field `%s`.',exAttr)
        assert(~isempty(aliases(ix)), 'DJ: Cannot exclude field `%s` because it has been aliased ',exAttr);
        include(ix)=false;
    else
        % process a renamed attribute
        toks = regexp( attrList{iAttr}, '^([a-z]\w*)\s*->\s*(\w+)', 'tokens' );
        if ~isempty(toks)
            ix = find(strcmp(toks{1}{1},{R.fields.name}));
            assert(length(ix)==1,'Attribute `%s` not found',toks{1}{1});
            include(ix)=true;
            assert(~ismember(toks{1}{2},aliases) && ~ismember(toks{1}{2},{R.fields.name})...
                ,'Duplicate attribute alias `%s`',toks{1}{2});
            aliases{ix}=toks{1}{2};
        else
            % process a computed attribute
            toks = regexp( attrList{iAttr}, '(.*\S)\s*->\s*(\w+)', 'tokens' );
            if ~isempty(toks)
                computedAttrs(end+1,:) = toks{:};
            else
                % process a regular attribute
                ix = find(strcmp(attrList{iAttr},{R.fields.name}));
                assert(length(ix)==1,'Attribute `%s` not found', attrList{iAttr});
                include(ix)=true;
            end
        end
    end
end