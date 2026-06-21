import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_cebmed/viewmodels/appointment_view_model.dart';
import 'package:frontend_cebmed/models/appointment.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_cebmed/services/api_service.dart';
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:flutter/material.dart';


// test simple
void main() {
  group('Rendez-vous et Calendrier', () {
    test(
      'setNotificationsEnabled(false) desactive les notifications', (){
      final viewModel = AppointmentViewModel();
      viewModel.setNotificationsEnabled(false);
      expect(
        viewModel.notificationsEnabled,
        false,
      );
    }
    );

    test(
      'retourne les rendez-vous du jour sélectionné',
          () {

        final appointments = [

          Appointment(
            id: 1,
            userId: 2,
            title: 'Dentiste',
            location: 'Paris',
            startTime: DateTime(2026, 6, 18, 9, 0),
            endTime: DateTime(2026, 6, 18, 9, 30),
            notificationsEnabled: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),

        ];

        final selectedDay =
        DateTime(2026, 6, 18);

        final appointmentsForDay =
        appointments.where((appointment) {

          return
            appointment.startTime.year ==
                selectedDay.year &&

                appointment.startTime.month ==
                    selectedDay.month &&

                appointment.startTime.day ==
                    selectedDay.day;

        }).toList();

        expect(
          appointmentsForDay.length,
          1,
        );

        expect(
          appointmentsForDay.first.title,
          'Dentiste',
        );

      },
    );

    test(
      'validateRequiredFields retourne true quand les champs sont remplis',
          () {

        final viewModel = AppointmentViewModel();
        viewModel.titleController.text = 'Dentiste';
        viewModel.locationController.text = 'Paris';

        final result = viewModel.validateRequiredFields();
        expect(result, true);

      },
    );
    test(
      'formattedDate retourne une date au format jj/mm/aaaa',
          () {
        final viewModel = AppointmentViewModel();
        viewModel.selectedDate = DateTime(2026, 6, 8);

        expect(
          viewModel.formattedDate,
          '08/06/2026',
        );
      },
    );
    test(
      'formattedStartTime retourne une heure au format HH:mm',
          () {
        final viewModel = AppointmentViewModel();
        viewModel.selectedStartTime =
        const TimeOfDay(
          hour: 9,
          minute: 5,
        );
        expect(
          viewModel.formattedStartTime, '09:05',
        );
      },
    );
    test(
      'setConsultationType modifie le type de consultation',
          () {
        final viewModel = AppointmentViewModel();

        viewModel.setConsultationType(
          'VIDEO',
        );
        expect(
          viewModel.consultationType,
          'VIDEO',
        );

      },
    );

    //test mock
    test ('saveAppointment envoie correctement les données vers l API', ()  async {
      SharedPreferences.setMockInitialValues({});
      ApiService.httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          endsWith('/appointments'),
        );
        final body = jsonDecode(request.body);

        expect(
          body['title'], 'Dentiste',
        );
        expect(
          body['location'], 'Cabinet médical',
        );
        expect(
          body['notifications_enabled'], false,
        );

        return http.Response(
          jsonEncode({
            'id': 1,
            'user_id': 2,
            'title': 'Dentiste',
            'description': null,
            'location': 'Cabinet médical',
            'start_time':
            '2026-06-18T09:00:00.000Z',
            'end_time':
            '2026-06-18T09:30:00.000Z',
            'notifications_enabled': false,
            'consultation_type': null,
            'reminder_delay': 60,
            'created_at': '2026-06-17T08:00:00.000Z',
            'updated_at': '2026-06-17T08:00:00.000Z',
          }),
          201,
          headers: {
            'content-type': 'application/json'
          },
        );
      });

      final viewModel = AppointmentViewModel(syncNotifications: false,
      );

      viewModel.titleController.text = 'Dentiste';
      viewModel.locationController.text = 'Cabinet médical';
      viewModel.selectedDate = DateTime(2026, 6, 18);

      viewModel.selectedStartTime = const TimeOfDay(
        hour: 9,
        minute: 0,
      );
      viewModel.selectedEndTime = const TimeOfDay(
        hour: 9,
        minute: 30,
      );
      viewModel.setNotificationsEnabled(false);

      final result = await viewModel.saveAppointment();
      expect(result, true);

      expect(viewModel.lastError, isNull,
      );
    },

    );

    test(
      'deleteAppointment supprime un rendez-vous existant',
          () async {
        SharedPreferences.setMockInitialValues({});
        ApiService.httpClient = MockClient((request) async {
          expect(
            request.method, 'DELETE',);

          expect(
            request.url.path,
            contains('/appointments'),
          );

          return http.Response('', 204,
          );

        });

        final appointment = Appointment(
          id: 1,
          userId: 2,
          title: 'Dentiste',
          location: 'Cabinet',
          startTime: DateTime(2026, 6, 18, 9, 0),
          endTime: DateTime(2026, 6, 18, 9, 30),
          notificationsEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final viewModel = AppointmentViewModel(
          initialAppointment: appointment,
          syncNotifications: false,
        );
        final result = await viewModel.deleteAppointment();
        expect(result, true);
        expect( viewModel.lastError, isNull,
        );

      },
    );
    test(
      'ApiService.getAppointments renvoie une liste de rendez-vous',
          () async {
        SharedPreferences.setMockInitialValues({});
        ApiService.httpClient = MockClient((request) async {

          expect(request.method, 'GET');
          expect(request.url.path,
            endsWith('/appointments'),
          );

          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 1,
                  'user_id': 2,
                  'title': 'Consultation cardiologue',
                  'description': 'Controle annuel',
                  'location': 'Paris',
                  'start_time': '2026-06-18T10:00:00.000Z',
                  'end_time': '2026-06-18T10:30:00.000Z',
                  'notifications_enabled': true,
                  'consultation_type': 'PRESENTIAL',
                  'reminder_delay': 60,
                  'created_at': '2026-06-17T08:00:00.000Z',
                  'updated_at': '2026-06-17T08:00:00.000Z',
                },
              ],
            }),
            200,
            headers: {
              'content-type': 'application/json',
            },
          );

        });

        final appointments = await ApiService.getAppointments();
        expect(
          appointments.length, 1,
        );
        expect(
          appointments.first.id, 1,
        );
        expect(
          appointments.first.title, 'Consultation cardiologue',
        );
        expect(
          appointments.first.location, 'Paris',
        );
        expect(
          appointments.first.notificationsEnabled, true,
        );

      },
    );


    // asynchrome
    test(
      'saveAppointment retourne false si les champs obligatoires sont vides',
          () async {
        final viewModel = AppointmentViewModel();
        final result = await viewModel.saveAppointment();
        expect(result, false);
        expect(
          viewModel.lastError,
          'Nom et lieu sont obligatoires',
        );
      },
    );
    test(
      "saveAppointment retourne false si l'heure de fin est inférieure à l'heure de début",
          () async {

        final viewModel = AppointmentViewModel();

        viewModel.titleController.text = 'Dentiste';
        viewModel.locationController.text = 'Paris';

        viewModel.selectedDate = DateTime(2026, 6, 18);

        viewModel.selectedStartTime =
        const TimeOfDay(hour: 10, minute: 0);

        viewModel.selectedEndTime =
        const TimeOfDay(hour: 9, minute: 0);

        final result = await viewModel.saveAppointment();
        expect(result, false);
        expect(
          viewModel.lastError,
          'L heure de fin doit etre apres l heure de debut',
        );
      },
    );
  }
  );
}
