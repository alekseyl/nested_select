class UserProfile < ApplicationRecord
  # Rails style guided+
  #-------------------- 1. includes and extend --------------
  #-------------------- 2. default scope --------------------
  #-------------------- 3. inner classes --------------------
  #-------------------- 5. attr related macros --------------
  #-------------------- 6. enums ----------------------------
  #-------------------- 7. scopes ---------------------------
  #-------------------- 8. has and belongs ------------------
  belongs_to :user
  # , inverse_of: :user_profile
  has_many :avatars
  # , inverse_of: :user_profile
  #-------------------- 9. accept nested macros  ------------
  #-------------------- 10. validation ----------------------
  #-------------------- 11. before/after callbacks ----------
  #-------------------- 12. enums related macros ------------
  #-------------------- 13. delegate macros -----------------
  #-------------------- 14. other macros (like devise's) ----
  #-------------------- should be placed after callbacks ----
  #-------------------- 15. public class methods ------------
  #-------------------- 16. instance public methods ---------
  #-------------------- 17. protected and private methods ---
end