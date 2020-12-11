%XMLREADPRIMITIVES Read extracted primitives into Matlab structure
% 
% [primitives] = xmlReadPrimitives(xmlFile_)
%
% Primitives in the XML-file xmlFile_ is read to a Matlab
% structure array.
%
% NOTE: The current version supports only reading primitive
% locations, location covariance and colours, but we happily accept
% your extension ;-)
%
% Output:
%   primitives  - Struct containing the "Primitive3D" primitives defined in XML.
%
% Input:
%   xmlFile_  - Full path to the XML file of primitive extraction
%               output (e.g. OpenDemos/Slam).
%
% Author(s):
%    Joni Kamarainen, CoVil in 2011-2012.
%
% Project:
%  Render3D
%
% References:
%
%  -
%
% Copyright:
%
%   Copyright (C) 2011 by Joni-Kristian Kamarainen (Joni.Kamarainen@lut.fi)
%
% See also XMLREAD.M .
%
function [primitives] = xmlReadPrimitives(xmlFile_)

% Let the Matlab function parse first
try
    xmlRoot = xmlread(xmlFile_);
catch errmsg
    error(['Reading the XML file ' xmlFile_ ' failed!']);
end

% Get primitive nodes  
xmlPrimitiveNodes = xmlRoot.getElementsByTagName('Primitive3D');

% Process every node (xml element named "Primitive3D")
%primitives = struct();
for i = 1:xmlPrimitiveNodes.getLength()
      
    priNode = xmlPrimitiveNodes.item(i-1);
    
    primitive = primitive_init(); % initialise requred fields
    err = 0;

    % Type "l": line/edge (not sure /Joni)
    primitive.type = priNode.getAttribute('type');
    
    % Process every sub-node (element) and process required data
    for j = 1:priNode.getLength()
   
        % Get the lowest level node (should be a known element)
        lnode = priNode.item(j-1);

        if (lnode.getNodeType() == lnode.ELEMENT_NODE)

            
            
            switch char(lnode.getNodeName())
             case 'Source2D',
              First_el = lnode.getElementsByTagName('First');
              Second_el = lnode.getElementsByTagName('Second');
              primitive.Source2D.First = str2num(First_el.item(0).getTextContent());
              primitive.Source2D.Second = str2num(Second_el.item(0).getTextContent());
             
             case 'Location',
              cartesian3D_el = lnode.getElementsByTagName('Cartesian3D');
              primitive.location.cartesian_coords(1) = str2num(cartesian3D_el.item(0).getAttribute('x'));
              primitive.location.cartesian_coords(2) = str2num(cartesian3D_el.item(0).getAttribute('y'));
              primitive.location.cartesian_coords(3) = str2num(cartesian3D_el.item(0).getAttribute('z'));
              
              cartesian3DCovariance_el = lnode.getElementsByTagName('Cartesian3DCovariance');
              primitive.location.cartesian_cov = str2num(cartesian3DCovariance_el.item(0).getTextContent);
              
             case 'Colors',
              left_el = lnode.getElementsByTagName('Left');
              left_rgb_el = left_el.item(0).getElementsByTagName('RGB');
              primitive.colors.left.rgb(1) = str2num(left_rgb_el.item(0).getAttribute('r'));
              primitive.colors.left.rgb(2) = str2num(left_rgb_el.item(0).getAttribute('g'));
              primitive.colors.left.rgb(3) = str2num(left_rgb_el.item(0).getAttribute('b'));
              primitive.colors.left.conf = str2num(left_rgb_el.item(0).getAttribute('conf'));

              right_el = lnode.getElementsByTagName('Right');
              right_rgb_el = right_el.item(0).getElementsByTagName('RGB');
              primitive.colors.right.rgb(1) = str2num(right_rgb_el.item(0).getAttribute('r'));
              primitive.colors.right.rgb(2) = str2num(right_rgb_el.item(0).getAttribute('g'));
              primitive.colors.right.rgb(3) = str2num(right_rgb_el.item(0).getAttribute('b'));
              primitive.colors.right.conf = str2num(right_rgb_el.item(0).getAttribute('conf'));

              middle_el = lnode.getElementsByTagName('Middle');
              middle_rgb_el = middle_el.item(0).getElementsByTagName('RGB');
              primitive.colors.middle.rgb(1) = str2num(middle_rgb_el.item(0).getAttribute('r'));
              primitive.colors.middle.rgb(2) = str2num(middle_rgb_el.item(0).getAttribute('g'));
              primitive.colors.middle.rgb(3) = str2num(middle_rgb_el.item(0).getAttribute('b'));
              primitive.colors.middle.conf = str2num(middle_rgb_el.item(0).getAttribute('conf'));

              % Take also covariances
              % left
              left_el = lnode.getElementsByTagName('LeftColorCovariance');
	      if (~isempty(left_el.item(0)))
              primitive.colors.left.covariance(1,1) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element11').item(0).getTextContent());
              primitive.colors.left.covariance(1,2) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element12').item(0).getTextContent());
              primitive.colors.left.covariance(1,3) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element13').item(0).getTextContent());
              primitive.colors.left.covariance(2,1) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element21').item(0).getTextContent());
              primitive.colors.left.covariance(2,2) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element22').item(0).getTextContent());
              primitive.colors.left.covariance(2,3) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element23').item(0).getTextContent());
              primitive.colors.left.covariance(3,1) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element31').item(0).getTextContent());
              primitive.colors.left.covariance(3,2) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element32').item(0).getTextContent());
              primitive.colors.left.covariance(3,3) = ...
                  str2num(left_el.item(0).getElementsByTagName('Element33').item(0).getTextContent());
              % right
              right_el = lnode.getElementsByTagName('RightColorCovariance');
              primitive.colors.right.covariance(1,1) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element11').item(0).getTextContent());
              primitive.colors.right.covariance(1,2) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element12').item(0).getTextContent());
              primitive.colors.right.covariance(1,3) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element13').item(0).getTextContent());
              primitive.colors.right.covariance(2,1) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element21').item(0).getTextContent());
              primitive.colors.right.covariance(2,2) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element22').item(0).getTextContent());
              primitive.colors.right.covariance(2,3) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element23').item(0).getTextContent());
              primitive.colors.right.covariance(3,1) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element31').item(0).getTextContent());
              primitive.colors.right.covariance(3,2) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element32').item(0).getTextContent());
              primitive.colors.right.covariance(3,3) = ...
                  str2num(right_el.item(0).getElementsByTagName('Element33').item(0).getTextContent());
              % middle
              middle_el = lnode.getElementsByTagName('MiddleColorCovariance');
              primitive.colors.middle.covariance(1,1) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element11').item(0).getTextContent());
              primitive.colors.middle.covariance(1,2) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element12').item(0).getTextContent());
              primitive.colors.middle.covariance(1,3) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element13').item(0).getTextContent());
              primitive.colors.middle.covariance(2,1) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element21').item(0).getTextContent());
              primitive.colors.middle.covariance(2,2) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element22').item(0).getTextContent());
              primitive.colors.middle.covariance(2,3) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element23').item(0).getTextContent());
              primitive.colors.middle.covariance(3,1) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element31').item(0).getTextContent());
              primitive.colors.middle.covariance(3,2) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element32').item(0).getTextContent());
              primitive.colors.middle.covariance(3,3) = ...
                  str2num(middle_el.item(0).getElementsByTagName('Element33').item(0).getTextContent());
              end;
             otherwise,
              % unimplemented field
            end;
        end;
    end
    primitives(i) = primitive;
end;


% --------------------------------------------------------------------
% Internal functions

function pri = primitive_init()


pri = [];
