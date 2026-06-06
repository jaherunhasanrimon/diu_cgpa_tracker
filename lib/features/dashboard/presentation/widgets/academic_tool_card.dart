import 'package:flutter/material.dart';


class AcademicToolCard extends StatelessWidget {

  final IconData icon;

  final String title;

  final String subtitle;


  const AcademicToolCard({

    super.key,

    required this.icon,

    required this.title,

    required this.subtitle,

  });


  @override
  Widget build(BuildContext context) {


    return Container(

      padding: const EdgeInsets.all(18),


      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(

          color: Colors.grey.shade200,

        ),

      ),


      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [


          CircleAvatar(

            child: Icon(icon),

          ),


          const SizedBox(height: 20),


          Text(

            title,

            style: const TextStyle(

              fontWeight: FontWeight.bold,

            ),

          ),


          const SizedBox(height: 5),


          Text(

            subtitle,

            style: const TextStyle(

              color: Colors.grey,

            ),

          ),


        ],

      ),

    );


  }

}