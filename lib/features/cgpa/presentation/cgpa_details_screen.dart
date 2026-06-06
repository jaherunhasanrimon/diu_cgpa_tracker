import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cgpa_provider.dart';
import '../repository/cgpa_repository.dart';


class CgpaDetailsScreen extends ConsumerWidget {

  const CgpaDetailsScreen({super.key});


  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {


    final cgpa =
    ref.watch(cgpaProvider);


    final results =
    CgpaRepository().getResults();



    return Scaffold(


      appBar: AppBar(

        title: const Text(
          'CGPA Details',
        ),

      ),



      body: Padding(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [


            Text(

              cgpa.toStringAsFixed(2),

              style: const TextStyle(

                fontSize: 42,

                fontWeight: FontWeight.bold,

                color: Color(0xff4F46E5),

              ),

            ),



            const Text(
              "Current CGPA",
            ),



            const SizedBox(
              height: 30,
            ),



            const Text(

              "Semester History",

              style: TextStyle(

                fontSize: 20,

                fontWeight: FontWeight.bold,

              ),

            ),



            const SizedBox(
              height: 20,
            ),



            Expanded(

              child: results.isEmpty

                  ? const Center(

                child: Text(
                  "No semester data found",
                ),

              )


                  : ListView.builder(


                itemCount:
                results.length,


                itemBuilder:
                    (context, index) {


                  final item =
                  results[index];



                  return Card(


                    elevation: 1,


                    child: ListTile(


                      title: Text(

                        "Semester ${item.semester}",

                        style:
                        const TextStyle(

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),



                      subtitle: Text(

                        "Credit: ${item.credit}",

                      ),



                      trailing: Text(

                        item.sgpa
                            .toStringAsFixed(2),


                        style:
                        const TextStyle(

                          fontSize: 18,

                          fontWeight:
                          FontWeight.bold,

                          color:
                          Color(0xff4F46E5),

                        ),

                      ),


                    ),


                  );


                },


              ),


            ),


          ],


        ),


      ),


    );


  }


}