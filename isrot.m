%ISROT Test if SO(3) rotation matrix
%
% ISROT(R) is true (1) if the argument is of dimension 3x3 or 3x3xN, else false (0).
%
% ISROT(R, 'valid') as above, but also checks the validity of the rotation
% matrix.
%
% Notes::
% - A valid rotation matrix has determinant of 1.
%
% See also ISHOMOG, ISROT2, ISVEC.




% Copyright (C) 1993-2017, by Peter I. Corke
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

function h = isrot(R, rtest)

    h = false;
    d = size(R);
    
    if ndims(R) >= 2
        if ~(all(d(1:2) == [3 3]))
            return %false
        end

        if nargin > 1
            for i = 1:size(R,3)
                RR = R(:,:,i);
                e = RR'*RR - eye(3,3);
                if norm(e) > 10*eps
                    return %false
                end
                e = abs(det(RR) - 1);
                if norm(e) > 10*eps
                    return %false
                end
            end
        end
    end

    h = true;
end