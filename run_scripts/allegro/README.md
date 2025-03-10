## NOTES:

1. **Combining Run Scripts**
   - While it is technically possible to combine both run scripts, **it is not recommended**.  
   - Training, especially for complex models, can take a significant amount of time.  
   - Users should assess the **model complexity** based on their desired outputs.  
   - The creators of the Allegro MLIP provide recommendations in their `configs.yaml` file:  
     🔗 [Nequip Full Config](https://github.com/mir-group/nequip/blob/main/configs/full.yaml)

2. **CPU Usage for Training**
   - Using **more CPU cores** is highly recommended for training due to the implementation of data parsing 
     parallelization from **version 0.5.5 onwards**
   - For more details, refer to the following discussion:  
     🔗 [mir-group/nequip#182](https://github.com/mir-group/nequip/issues/182)  
   - Alternatively, review the **0.5.5 documentation** for a deeper understanding of the update.

3. **Managing Training, Validation, and Test Sets**
   - If you plan to create test sets, ensure that in your `input.yaml` file,  
     **the sum of training and validation datasets does not reach 100%**.  
   - You must leave some data aside for **testing**.  
   - Testing is performed using the following command:
     ```bash
     nequip-evaluate
     ```
