BeginPackage["CommitteeIsserlis`"]
  IsserlisTheorem::usage = 
    "Compute the expectation of a polynomial over a multivariate gaussian."
  RawMoment::usage = 
    "Compute the moment of a multivariate Gaussian."
  IsserlisCovariance::usage = 
    "Compute the covariance of a polynomial over a multivariate gaussian."

  StudentHiddenUnits = 1; TeacherHiddenUnits = 1;

  (*The extra field is the artificial noise*)
  TotalDimension = StudentHiddenUnits+TeacherHiddenUnits+1;

  lfs = \[Lambda]
  lft = (Superscript[\[Lambda], t])


  (*Extended Local Fields*)
  LocalFields = Range[TotalDimension];
  For[ita = 1, ita <= StudentHiddenUnits, ita++, LocalFields[[ita]] = lfs[ita] ]; (* the iterator is not a local variable! Be careful!!*)
  For[itb = StudentHiddenUnits+1, itb <= StudentHiddenUnits+TeacherHiddenUnits, itb++, LocalFields[[itb]] = lft[itb-StudentHiddenUnits] ];
  LocalFields[[TotalDimension]] = \[Xi];

  student = 1/StudentHiddenUnits * Sum[j^2, {j, LocalFields[[1;;StudentHiddenUnits]]}]
  teacher = 1/TeacherHiddenUnits * Sum[r^2, {r, LocalFields[[StudentHiddenUnits+1;;StudentHiddenUnits+TeacherHiddenUnits]]}]
  displacement = teacher - student + \[Xi]


  (*Extended Covariance Matrix for local field and artificial noise*)
  Omega = Normal@SymmetrizedArray[{i_, j_} -> omega[i, j], {TotalDimension, TotalDimension}, Symmetric[{1, 2}] ] /. {
        omega[i_, j_] :> If[i <= StudentHiddenUnits,
          If[j <= StudentHiddenUnits,
            q[i,j],
            If[j == TotalDimension,
              0,
              m[i,j-StudentHiddenUnits]
            ]
          ],
          If[j == TotalDimension,
            If[i == TotalDimension, \[CapitalDelta], 0],
            \[Rho][i-StudentHiddenUnits,j-StudentHiddenUnits]
          ]
        ]
      };
  
  (*The moment generating function for local fields*)
  LFMomentGeneratingFunction = Exp[1/2* LocalFields.Omega.LocalFields];
  Begin["Private`"]
  

  RawMoment[exponents__] := 
    Module[{derivativespairs, result},
      derivativepairs = Transpose@{LocalFields, List[exponents]};
      result = D[LFMomentGeneratingFunction, ##] & @@ derivativepairs;
      result /. {
        lfs[i_] :> 0,
        lft[i_] :> 0,
        \[Xi] :> 0
      }
    ];

  IsserlisTheorem[polynomial_] :=
    (* CoefficientRules[polynomial, LocalFields]; *)
    ExpandAll[Total[Replace[
      CoefficientRules[polynomial, LocalFields],
      {Rule -> Times, List -> RawMoment}, {2, 3}, Heads -> True
    ] ] ];

  IsserlisCovariance[polynomial1_, polynomial2_] :=
    ExpandAll[
      IsserlisTheorem[polynomial1*polynomial2] - IsserlisTheorem[polynomial1]*IsserlisTheorem[polynomial2]
    ];

    
  End[]
EndPackage[]