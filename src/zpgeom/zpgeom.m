classdef zpgeom
    
    
    
    
    methods (Static)
        
        % Converts k0 (fx, fy) into (x,y,z) on zone plate
        %
        % Operates in pure frequencies, i.e., no sense of pupil coordinates, but assumes object to be oriented vertically
        %
        % Function (1) in notes
        % f = (fx, fy) is the input frequency coordinates
        % n is the normal vector to the zone plate
        % p is the vector from the origin to zone plate along the optical axis connecting object and image points

        function r = freq2zpCoord(f, n, p, lambda)
            fx = f(1);
            fy = f(2);

            % Make sure u and n are unit vectors:
            p0 = norm(p, 2);
            u = p/norm(p, 2);
            n = n/norm(n, 2);
            
            % build l-hat vector:
            l = [fx, fy, 1/lambda * sqrt(1-((fx * lambda)^2 + (fy * lambda)^2))];
            l = l/norm(l, 2);
            
            % ensure that p3 and l3 have the same sign:
            signCorrection = sign(l(3))/sign(p(3));
            l(3) = l(3) * signCorrection;
            
            % solve p0 = l_0 + d*l for d:
            d = p0  * (u * n') / (l * n');
            r = d*l;
        end
        
        % Converts (x,y,z) of a zone plate back to frequency coords via its
        % direction cosines.  Recall that the direction cosines vector is
        % related to spatial frequencies by a factor of lambda
        function f = zpCoord2Freq(r, lambda)
            f(1:2) = r(1:2)/norm(r,2) / lambda;
        end
        
        % Converts coords r (x,y,z) to 2-d zone plate coords [ux, uy].
        % Requires ZP-oAxis intersection vector p and basis vectors for zp
        % plane
        function U = zpXYZ2UxUy(r, p, b)
            % make sure basis vectors are normalized:
            b = b/norm(b, 2);
            
            % point in cartesian coordinates wrt p0:
            rp = r - p;
            
            % project onto basis:
            U(1) = rp * b(1,:)';
            U(2) = rp * b(2,:)';
            U(3) = rp * b(3,:)';

        end
        
        % Inverse of previous function
        function r = zpUxUy2XYZ(U, p0, b)
           % make sure basis vectors are normalized:
            b = b/norm(b, 2);
            
            % convert U to cartesian:
            x = U(1)*b(1,:)';
            y = U(2)*b(2,:)';
            
            % write in terms of l0 origin
            r = p0 + x' + y';
        end
        
        function opd = xyz2OPD(r_o, p, q, lambda_um)
            dPNorm = norm(p, 2);
            dPHat = p/dPNorm;
            
            dQ = q * dPHat;
            r_i = (p + dQ) - r_o;
            
            opd = (norm(r_o, 2) + norm(r_i, 2))/lambda_um;
            
            
        end
        
        
    end
    
end
