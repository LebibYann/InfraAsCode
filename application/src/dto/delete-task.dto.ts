import { IsISO8601, IsNotEmpty } from 'class-validator';

export class DeleteTaskDto {
  @IsISO8601()
  @IsNotEmpty()
  request_timestamp: string;
}
