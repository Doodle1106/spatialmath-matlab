%Quaternion Quaternion class
%
% A quaternion is 4-element mathematical object comprising a scalar s, and
% a vector v and is typically written: q = s <<vx, vy, vz>>.
%
% A quaternion of unit length can be used to represent 3D orientation and
% is implemented by the subclass UnitQuaternion.
%
% Methods::
%  Quaternion        constructor
%  Quaternion.pure   constructor, pure quaternion
%  inv               inverse
%  conj              conjugate
%  norm              norm, or length
%  unit              unitized quaternion
%  dot               derivative of quaternion with angular velocity w
%  inner             inner product
%  plot              plot a coordinate frame representing orientation of quaternion
%  animate           animates a coordinate frame representing changing orientation
%
% Conversion methods::
%  double    quaternion elements as 4-vector
%
% Overloaded operators::
%  q*q2      quaternion (Hamilton) product
%  s*q       elementwise multiplication of quaternion by scalar
%  q/q2      q*q2.inv
%  q^n       q to power n (integer only)
%  q+q2      elementwise sum of quaternions (4-vector)
%  q-q2      elementwise difference of quaternions (4-vector
%  q1==q2    test for quaternion equality
%  q1~=q2    test for quaternion inequality
%
% Properties (read only)::
%  s         real part
%  v         vector part
%
% Notes::
% - Quaternion objects can be used in vectors and arrays.
%
% References::
% - Animating rotation with quaternion curves,
%   K. Shoemake,
%   in Proceedings of ACM SIGGRAPH, (San Fran cisco), pp. 245-254, 1985.
% - On homogeneous transforms, quaternions, and computational efficiency,
%   J. Funda, R. Taylor, and R. Paul,
%   IEEE Transactions on Robotics and Automation, vol. 6, pp. 382-388, June 1990.
% - Robotics, Vision & Control,
%   P. Corke, Springer 2011.
%
% See also UnitQuaternion.

% TODO
% properties s, v for the vector case


% Copyright (C) 1993-2015, by Peter I. Corke
%
% This file is part of The Robotics Toolbox for MATLAB (RTB).
%
% RTB is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% RTB is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Leser General Public License
% along with RTB.  If not, see <http://www.gnu.org/licenses/>.
%
% http://www.petercorke.com

% TODO
%  constructor handles R, T trajectory and returns vector
%  .r, .t on a quaternion vector??

classdef Quaternion
    
    properties (SetAccess = protected, GetAccess=public)
        s       % scalar part
        v       % vector part
    end
    
    
    methods
        
        function q = Quaternion(s, v)
            %Quaternion.Quaternion Constructor for quaternion objects
            %
            % Q = Quaternion is a zero quaternion
            %
            % Q = Quaternion([S V1 V2 V3]) is a quaternion formed by specifying directly its 4 elements
            %
            % Q = Quaternion(S, V) is a quaternion formed from the scalar S and vector
            % part V (1x3)
            %
            % Notes::
            % - The constructor does not handle the vector case.
            
            if nargin == 0
                q.v = [0,0,0];
                q.s = 0;
            elseif isa(s, 'Quaternion')
                q.s = s.s;
                q.v = s.v;
            elseif nargin == 2 && isscalar(s) && isvec(v,3)
                q.s = s;
                q.v = v(:)';
            elseif nargin == 1 && isvec(s,4)
                s = s(:)';
                q.s = s(1);
                q.v = s(2:4);
            else
                error ('RTB:Quaternion:badarg', 'bad argument to quaternion constructor');
            end
            
        end
        
        function uq = new(q, varargin)
            uq = Quaternion(varargin{:});
        end
        
        function qo = set.s(q, s)
            if ~isreal(s) || ~isscalar(s)
                error('RTB:Quaternion:badarg', 's must be real scalar');
            end
            
            qo = q;
            qo.s = s;
        end
        
        function qo = set.v(q, v)
            if ~isvec(v,3)
                error('RTB:Quaternion:badarg', 'v must be a real 3-vector');
            end
            
            qo = q;
            qo.v = v(:)';
        end
        
%         function s = get.s(q)
%             s = [q.s]';
%         end
%         
%         function v = get.v(q)
%             [q.v]
%             v = reshape([q.v]', 3, [])';
%         end
            
        function display(q)
            %Quaternion.display Display quaternion
            %
            % Q.display() displays a compact string representation of the quaternion's value
            % as a 4-tuple.  If Q is a vector then S has one line per element.
            %
            % Notes::
            % - This method is invoked implicitly at the command line when the result
            %   of an expression is a Quaternion object and the command has no trailing
            %   semicolon.
            %
            % See also Quaternion.char.
            
            loose = strcmp( get(0, 'FormatSpacing'), 'loose');
            if loose
                disp(' ');
            end
            disp([inputname(1), ' = '])
            if loose
                disp(' ');
            end
            disp(char(q))
            if loose
                disp(' ');
            end
        end
        
       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% QUATERNION FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

        function c = conj(q)
            %Quaternion.conj Conjugate of a quaternion
            %
            % QI = Q.conj() is a quaternion object representing the conjugate of Q.
            %
            % Notes::
            % - Supports quaternion vector.
            c = q.new(q.s, -q.v);
        end
        
        function qi = inv(q)
            %Quaternion.inv Invert a quaternion
            %
            % QI = Q.inv() is a quaternion object representing the inverse of Q.
            %
            % Notes::
            % - Supports quaternion vector.
            
            for i=1:length(q)
                n2 = sum( q(i).double.^2 );
                qi(i) = Quaternion([q(i).s -q(i).v]/ n2);
            end
        end
        
        function qu = unit(q)
            %Quaternion.unit Unitize a quaternion
            %
            % QU = Q.unit() is a unit-quaternion representing the same orientation as Q.
            %
            % Notes::
            % - Supports quaternion vector.
            %
            % See also Quaternion.norm.
            
            for i=1:length(q)
                qu(i) = Quaternion( q(i).double / norm(q(i)) );
            end
        end

        function qd = dot(q, omega)
            %Quaternion.dot Quaternion derivative
            %
            % QD = Q.dot(omega) is the rate of change of a frame with attitude Q and
            % angular velocity OMEGA (1x3) expressed as a quaternion.
            %
            % Notes::
            % - This is not a group operator, but it is useful to have the result as a
            %   quaternion.
            E = q.s*eye(3,3) - skew(q.v);
            omega = omega(:);
            qd = Quaternion([-0.5*q.v*omega; 0.5*E*omega]);
        end
        
        function n = norm(q)
            %Quaternion.norm Quaternion magnitude
            %
            % QN = Q.norm(Q) is the scalar norm or magnitude of the quaternion Q.
            %
            % Notes::
            % - This is the Euclidean norm of the quaternion written as a 4-vector.
            % - A unit-quaternion has a norm of one.
            %
            % See also Quaternion.inner, Quaternion.unit.
            
            n = colnorm(double(q)')';
        end
        
        function n = inner(q1, q2)
            %Quaternion.inner Quaternion inner product
            %
            % V = Q1.inner(Q2) is the inner (dot) product of two vectors (1x4),
            % comprising the elements of Q1 and Q2 respectively.
            %
            % Notes::
            % - Q1.inner(Q1) is the same as Q1.norm().
            %
            % See also Quaternion.norm.
            
            n = double(q1)*double(q2)';
        end
       
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% ARITHMETIC OPERATORS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
        
        function qp = mtimes(q1, q2)
            %Quaternion.mtimes Multiply a quaternion object
            %
            % Q1*Q2   is a quaternion formed by the Hamilton product of two quaternions.
            % Q*S     is the element-wise multiplication of quaternion elements by the scalar S.
            %
            % Notes::
            % - Overloaded operator '*'
            % - For case Q1*Q2 both can be an N-vector, result is elementwise
            %   multiplication.
            % - For case Q1*Q2 if Q1 scalar and Q2 a vector, scalar multiplies each
            %   element.
            % - For case Q1*Q2 if Q2 scalar and Q1 a vector, each element multiplies
            %   scalar.
            %
            % See also Quaternion.mrdivide, Quaternion.mpower.
            
            if isa(q2, 'Quaternion')
                %QQMUL  Multiply quaternion by quaternion
                %
                % QQ = qqmul(Q1, Q2) is the product of two quaternions.
                
                if length(q1) == length(q2)
                    for i=1:length(q1)
                        % decompose into scalar and vector components
                        s1 = q1(i).s;  v1 = q1(i).v;
                        s2 = q2(i).s;  v2 = q2(i).v;
                        
                        % form the product
                        qp(i) = q2.new([s1*s2-v1*v2' s1*v2+s2*v1+cross(v1,v2)]);
                    end
                elseif isscalar(q1)
                    s1 = q1.s;  v1 = q1.v;
                    
                    for i=1:length(q2)
                        % decompose into scalar and vector components
                        s2 = q2(i).s;  v2 = q2(i).v;
                        
                        % form the product
                        qp(i) = q2.new([s1*s2-v1*v2' s1*v2+s2*v1+cross(v1,v2)]);
                    end
                elseif isscalar(q2)
                    s2 = q2.s;  v2 = q2.v;
                    
                    for i=1:length(q1)
                        % decompose into scalar and vector components
                        s1 = q1(i).s;  v1 = q1(i).v;
                        
                        % form the product
                        qp(i) = q2.new([s1*s2-v1*v2' s1*v2+s2*v1+cross(v1,v2)]);
                    end
                else
                    error('RTB:quaternion:badarg', '* operand length mismatch');
                end
                
            elseif isa(q1, 'Quaternion') && isa(q2, 'double')
                
                %QSMUL  Multiply quaternion
                %
                % Q = qsmul(Q, S) multiply quaternion by real scalar.
                %
                
                if length(q2) == 1
                    qp = Quaternion( double(q1)*q2);
                else
                    error('RTB:Quaternion:badarg', 'quaternion-double product: must be a scalar');
                end              
            else
                error('RTB:Quaternion:badarg', 'quaternion product: incorrect right hand operand');
            end
        end
       
        function qq = mrdivide(q1, q2)
            %Quaternion.mrdivide Quaternion quotient.
            %
            % Q1/Q2   is a quaternion formed by Hamilton product of Q1 and inv(Q2).
            % Q/S     is the element-wise division of quaternion elements by the scalar S.
            %
            % Notes::
            % - Overloaded operator '/'
            % - For case Q1/Q2 both can be an N-vector, result is elementwise
            %   division.
            % - For case Q1/Q2 if Q1 scalar and Q2 a vector, scalar is divided by each
            %   element.
            % - For case Q1/Q2 if Q2 scalar and Q1 a vector, each element divided by
            %   scalar.
            %
            % See also Quaternion.mtimes, Quaternion.mpower, Quaternion.plus, Quaternion.minus.
            
            if isa(q2, 'Quaternion')
                %QQDIV  Divide quaternion by quaternion
                %
                % QQ = qqdiv(Q1, Q2) is the quotient of two quaternions.
                
                if length(q1) == length(q2)
                    for i=1:length(q1)
                        
                        % form the quotient
                        qq(i) = q1(i) * inv(q2(i));
                    end
                elseif isscalar(q1)
                    s1 = q1.s;  v1 = q1.v;
                    
                    for i=1:length(q2)
                      
                        % form the quotient
                        qq(i) = q1 * inv(q2(i));
                    end
                elseif isscalar(q2)
                    
                    for i=1:length(q1)
                        
                        % form the quotient
                        qq(i) = q1(i) * inv(q2);
                    end
                else
                    error('RTB:quaternion:badarg', '/ operand length mismatch');
                end
                
            elseif isa(q1, 'Quaternion') && isa(q2, 'double')
                
                %QSDIV  Divide quaternion by scalar
                %
                % Q = qsdiv(Q, S) divide quaternion by real scalar.
                %
                
                if length(q2) == 1
                    qp = Quaternion( double(q1)/q2);
                else
                    error('RTB:Quaternion:badarg', 'quaternion-double quotient: must be a scalar');
                end              
            else
                error('RTB:Quaternion:badarg', 'quaternion quotient: incorrect right hand operand');
            end
        end

                
        function qp = mpower(q, p)
            %Quaternion.mpower Raise quaternion to integer power
            %
            % Q^N is the quaternion Q raised to the integer power N.
            %
            % Notes::
            % - Overloaded operator '^'
            % - Computed by repeated multiplication.
            % - If the argument is a unit-quaternion, the result will be a
            %   unit quaternion.
            %
            % See also Quaternion.mrdivide, Quaternion.mpower, Quaternion.plus, Quaternion.minus.
            
            % check that exponent is an integer
            if (p - floor(p)) ~= 0
                error('quaternion exponent must be integer');
            end
            
            qp = q.new();
            
            % multiply by itself so many times
            for i = 2:abs(p)
                qp = qp * q;
            end
            
            % if exponent was negative, invert it
            if p<0
                qp = inv(qp);
            end
        end
        
        
        function qp = plus(q1, q2)
            %PLUS Add quaternions
            %
            % Q1+Q2 is the element-wise sum of quaternion elements.
            % Q1+V  is the element-wise sum of Q1 and vector V (1x4)
            %
            % Notes::
            % - Overloaded operator '+'
            % - This is not a group operator, but it is useful to have the result as a
            %   quaternion.
            %
            % See also Quaternion.minus.
            
            if isa(q2, 'Quaternion')
                qp = Quaternion(double(q1) + double(q2));
            elseif isvec(q2, 4)
                qp = Quaternion(q1);
                q2 = q2(:)';
                qp.s = qp.s + q2(1);
                qp.v = qp.v + q2(2:4);
            end
        end
        
        function qp = minus(q1, q2)
            %Quaternion.minus Subtract quaternions
            %
            % Q1-Q2 is the element-wise difference of quaternion elements.
            %
            % Notes::
            % - Overloaded operator '-'
            % - This is not a group operator, but it is useful to have the result as a
            %   quaternion.
            %
            % See also Quaternion.plus.
            
            if isa(q2, 'Quaternion')
                
                qp = Quaternion(double(q1) - double(q2));
            end
        end
        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% RELATIONAL OPERATORS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

        function e = eq(q1, q2)
            %EQ Test quaternion equality
            %
            % Q1==Q2 is true if the quaternions Q1 and Q2 are equal.
            %
            % Notes::
            % - Overloaded operator '=='.
            % - Note that for unit Quaternions Q and -Q are the equivalent
            %   rotation, so non-equality does not mean rotations are not
            %   equivalent.
            % - If Q1 is a vector of quaternions, each element is compared to
            %   Q2 and the result is a logical array of the same length as Q1.
            % - If Q2 is a vector of quaternions, each element is compared to
            %   Q1 and the result is a logical array of the same length as Q2.
            % - If Q1 and Q2 are vectors of the same length, then the result
            %   is a logical array of the same length.
            %
            % See also Quaternion.ne.
            if (numel(q1) == 1) && (numel(q2) == 1)
                e = all( eq(q1.double, q2.double) );
            elseif (numel(q1) >  1) && (numel(q2) == 1)
                e = zeros(1, numel(q1));
                for i=1:numel(q1)
                    e(i) = q1(i) == q2;
                end
            elseif (numel(q1) == 1) && (numel(q2) > 1)
                e = zeros(1, numel(q2));
                for i=1:numel(q2)
                    e(i) = q2(i) == q1;
                end
            elseif numel(q1) == numel(q2)
                e = zeros(1, numel(q1));
                for i=1:numel(q1)
                    e(i) = q1(i) == q2(i);
                end
            else
                error('RTB:quaternion:badargs');
            end
        end
        
        function e = ne(q1, q2)
            %NE Test quaternion inequality
            %
            % Q1~=Q2 is true if the quaternions Q1 and Q2 are not equal.
            %
            % Notes::
            % - Overloaded operator '~='
            % - Note that for unit Quaternions Q and -Q are the equivalent
            %   rotation, so non-equality does not mean rotations are not
            %   equivalent.
            % - If Q1 is a vector of quaternions, each element is compared to
            %   Q2 and the result is a logical array of the same length as Q1.
            % - If Q2 is a vector of quaternions, each element is compared to
            %   Q1 and the result is a logical array of the same length as Q2.
            % - If Q1 and Q2 are vectors of the same length, then the result
            %   is a logical array of the same length.
            %
            % See also Quaternion.eq.
            if (numel(q1) == 1) && (numel(q2) == 1)
                e = all( ne(q1.double, q2.double) );
            elseif (numel(q1) >  1) && (numel(q2) == 1)
                e = zeros(1, numel(q1));
                for i=1:numel(q1)
                    e(i) = q1(i) ~= q2;
                end
            elseif (numel(q1) == 1) && (numel(q2) > 1)
                e = zeros(1, numel(q2));
                for i=1:numel(q2)
                    e(i) = q2(i) ~= q1;
                end
            elseif numel(q1) == numel(q2)
                e = zeros(1, numel(q1));
                for i=1:numel(q1)
                    e(i) = q1(i) ~= q2(i);
                end
            else
                error('RTB:quaternion:badargs');
            end
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% GRAPHICS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function hout = plot(Q, varargin)
            %Quaternion.plot Plot a quaternion object
            %
            % Q.plot(options) plots the quaternion as an oriented coordinate frame.
            %
            % h = Q.plot(options) as above but returns a handle which can be used for animation.
            %
            % Options::
            % Options are passed to trplot and include:
            %
            % 'color',C          The color to draw the axes, MATLAB colorspec C
            % 'frame',F          The frame is named {F} and the subscript on the axis labels is F.
            % 'view',V           Set plot view parameters V=[az el] angles, or 'auto'
            %                    for view toward origin of coordinate frame
            % 'handle',h         Update the specified handle
            %
            % See also trplot.
            
            %axis([-1 1 -1 1 -1 1])
            
            h = trplot( Q.R, varargin{:});
            if nargout > 0
                hout = h;
            end
        end
        
        function animate(Q, varargin)
            %Quaternion.animate Animate a quaternion object
            %
            % Q.animate(options) animates a quaternion array Q as a 3D coordinate frame.
            %
            % Q.animate(QF, options) animates a 3D coordinate frame moving from
            % orientation Q to orientation QF.
            %
            % Options::
            % Options are passed to tranimate and include:
            %
            %  'fps', fps    Number of frames per second to display (default 10)
            %  'nsteps', n   The number of steps along the path (default 50)
            %  'axis',A      Axis bounds [xmin, xmax, ymin, ymax, zmin, zmax]
            %  'movie',M     Save frames as files in the folder M
            %  'cleanup'     Remove the frame at end of animation
            %  'noxyz'       Don't label the axes
            %  'rgb'         Color the axes in the order x=red, y=green, z=blue
            %  'retain'      Retain frames, don't animate
            %  Additional options are passed through to TRPLOT.
            %
            % See also tranimate, trplot.
            
            if nargin > 1 && isa(varargin{1}, 'Quaternion')
                QF = varargin{1};
                tranimate(Q.R, QF.R, varargin{2:end});
            else
                tranimate(Q.R, varargin{:});
            end
        end
        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% TYPE CONVERSION METHODS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function s = char(q)
            %Quaternion.char Convert to string
            %
            % S = Q.char() is a compact string representation of the quaternion's value
            % as a 4-tuple.  If Q is a vector then S has one line per element.
            
            if length(q) > 1
                s = '';
                for qq = q;
                    s = char(s, char(qq));
                end
                return
            end
            s = [num2str(q.s), ' << ' ...
                num2str(q.v(1)) ', ' num2str(q.v(2)) ', '   num2str(q.v(3)) ' >>'];
        end
                
        function v = double(q)
            %Quaternion.double Convert a quaternion to a 4-element vector
            %
            % V = Q.double() is a 4-vector comprising the quaternion.
            %
            % Notes::
            % - Supports quaternion vector, result is 6xN matrix.
            %
            % elements [s vx vy vz].
            
            for i=1:length(q)
                v(i,:) = [q(i).s q(i).v];
            end
        end
 
    end % methods
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% STATIC FACTORY METHODS, ALTERNATIVE CONSTRUCTORS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Static)
        
        function q = pure(v)
            
            if ~isvec(v)
                error('RTB:Quaternion:bad arg', 'must be a 3-vector');
            end
            q = Quaternion(0, v(:));
        end
    end  % static methods
end
